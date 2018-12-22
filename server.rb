require "sinatra"
require "sinatra-websocket"
require "colorize"

require_relative "utilities"

require_relative "models/node"
require_relative "models/message"

require_relative "config/blockchain_config"

require_relative "services/networking_service"
require_relative "services/block_service"
require_relative "services/transfer_service"
require_relative "services/message_service"
require_relative "services/node_service"
require_relative "services/update_state_service"

transactions = []
recent_messages = Set.new
me = Node.new(port: settings.port)

nodes = []
seed_port = ARGV[0]
if seed_port && seed_port != "-p"
  nodes = NetworkingService::fetch_peers(to: seed_port, from: me.port)
  Utilities::check_for_eviction(nodes: nodes)
end

blockchain = BlockchainConfig::generate_initial_blockchain
me.fork_choice(blockchain: blockchain)

Utilities::log "Node #{settings.port} coming online".green

UpdateStateService::share_state(
  from: me,
  transactions: transactions,
  blockchain: me.blockchain
)

post "/peers" do
  params = JSON.parse(request.body.read)
  message = Message.from_params(params: params)
  NodeService.add_node_if_missing(nodes: nodes, port: message.port)

  NodeService.render_peers(nodes: nodes, me: me)
end

post "/transfer" do
  params = JSON.parse(request.body.read)
  Utilities::log "Now Transfering $#{params['amount']} to #{params['to']}!".cyan

  TransferService::send_money(
    node: me,
    nodes: nodes,
    to_port: params["to"],
    amount: params["amount"],
    transactions: transactions
  )

  true
end

get "/public_key" do
  me.public_key
end

post "/create_block" do
  Utilities::log "Now Creating A Block!".cyan

  BlockService.generate_block(
    node: me,
    nodes: nodes,
    transactions: transactions
  )

  true
end

post "/gossip" do
  params = JSON.parse(request.body.read)
  message = Message.from_params(params: params)

  # Simulate latency
  sleep 0.2

  halt 200 if MessageService.should_not_process(
    message: message,
    recent_messages: recent_messages,
    me: me
  )

  NodeService.update_nodes_from_message(
    nodes: nodes,
    message: message
  )

  MessageService.handle_message(
    message: message,
    transactions: transactions,
    me: me,
    nodes: nodes
  )

  UpdateStateService::share_state(
    from: me,
    transactions: transactions,
    blockchain: me.blockchain
  )
end
