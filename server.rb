require "sinatra"
require "sinatra-websocket"
require "colorize"
require "Haml"

require_relative "utilities"
require_relative "node"
require_relative "constants"
require_relative "transaction"
require_relative "block"
require_relative "blockchain"
require_relative "message"
require_relative "networking_service"
require_relative "blockchain_config"
require_relative "block_service"
require_relative "transfer_service"

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

post "/peers" do
  params = JSON.parse(request.body.read)
  message = Message.from_params(params: params)
  node = nodes.find { |node| node.port == message.port }

  if !node
    new_node = Node.new(
      port: message.port,
      is_peer: true
    )
    nodes.push(new_node)
    Utilities::check_for_eviction(nodes: nodes)
  end

  (Utilities::get_peers(nodes: nodes) + [me]).map(&:display_hash).to_json
end

post "/transfer" do
  Utilities::log "Now Transfering $#{params['amount']} to #{params['port']}!".cyan
  params = JSON.parse(request.body.read)

  new_transaction = TransferService::send_money(
    node: me,
    nodes: nodes,
    to_port: params["to"],
    amount: params["amount"]
  )

  transactions.push(new_transaction)

  true
end

get "/public_key" do
  me.public_key.to_text
end

post "/create_block" do
  Utilities::log "Now Creating A Block!".cyan

  block = BlockService.generate_block(
    node: me,
    nodes: nodes,
    transactions: transactions
  )

  transactions = []
  true
end

post "/gossip" do
  params = JSON.parse(request.body.read)
  message = Message.from_params(params: params)

  # Check whether we have seen this message already
  if recent_messages.include? message.uuid
    Utilities::log "Seen message #{message.uuid} before, ignoring".red
    halt 200
  end
  recent_messages.add(message.uuid)

  if me.port == message.port
    Utilities::log "Message port is from me, ignoring".red
    halt 200
  end

  Utilities::log "RECEIVED MESSAGE".blue.on_red.blink
  Utilities::log (message.type.to_s.magenta + "\t" + message.uuid.green)

  # Update our state based on the message content.
  #  If we know of this peer already, update it, otherwise add it to our list of peers
  node = nodes.find { |node| node.port == message.port }

  if node
    node.last_heard_from = Time.now
  else
    new_node = Node.new(
      port: message.port,
      is_peer: true
    )

    nodes.push(new_node)
    Utilities::check_for_eviction(nodes: nodes)
  end

  if message.type == Transaction
    transaction = Transaction.from_params(params: message.payload)
    if transaction.is_valid?
      transactions.push(transaction)
    else
      Utilities::log "Will not add invalid transaction!".red
    end
  elsif message.type = Blockchain
    Utilities::log "RECEIVED NEW BLOCKCHAIN".red
    blockchain = Blockchain.from_params(params: message.payload)
    me.fork_choice(blockchain: blockchain)
  end

  Utilities::log "now my blockchain is:"
  Utilities::log me.blockchain
  Utilities::log "\n\n\n"
end
