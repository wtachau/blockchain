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


###########
# Helpers #
###########

def get_peers(nodes:)
  nodes.select(&:is_peer)
end

def send_message_to_peers(message:, peers:)
  peers.each do |peer|
    Utilities::log "Sending message #{message.uuid} to port #{peer.port}".light_blue

    Utilities::make_request(
      port: peer.port,
      path: "gossip",
      body: message.to_hash,
      post: true
    )
  end
end

def check_for_eviction(nodes:)
  peers = get_peers(nodes: nodes)
  if peers.count > Constants::MAX_PEERS_COUNT
    peer_to_remove = peers.sample
    peer_to_remove.is_peer = false
  end
end

nodes = []
seed_port = ARGV[0]
me = Node.new(port: settings.port)

if seed_port && seed_port != "-p"

  peers_response = Utilities::make_request(
    port: seed_port,
    path: "peers",
    body: Message.new(
      port: me.port
    ).to_hash,
    post: true
  )

  nodes = JSON.parse(peers_response).map { |params|
    node = Node.from_params(params: params)
    node.is_peer = true
    node
  }.select { |p| p.port != me.port }
  check_for_eviction(nodes: nodes)
end


initial_money_node = Node.new(port: Constants::INITIAL_MONEY_PORT)
initial_transaction = Transaction.new(
  to: initial_money_node.public_key,
  amount: Constants::INITIAL_MONEY_AMOUNT,
  genesis: true
)
genesis_block = Block.new(
  transactions: [initial_transaction],
)

me.sign(transaction: initial_transaction)


if File.file?(Constants::GENESIS_BLOCK_NONCE_FILENAME)
  genesis_block.nonce = Marshal.load(File.binread(Constants::GENESIS_BLOCK_NONCE_FILENAME))
end

if genesis_block.nonce.nil? || !genesis_block.is_valid?
  genesis_block.find_matching_nonce

  File.open(Constants::GENESIS_BLOCK_NONCE_FILENAME, 'wb') { |f|
    f.write(Marshal.dump(genesis_block.nonce))
  }
end

blockchain = Blockchain.new(blocks: [genesis_block])

recent_messages = Set.new
transactions = []
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
    check_for_eviction(nodes: nodes)
  end

  (get_peers(nodes: nodes) + [me]).map(&:display_hash).to_json
end

post "/transfer" do
  params = JSON.parse(request.body.read)

  recipient_public_key = Utilities::make_request(
    port: params["to"],
    path: "public_key"
  )

  transaction = me.create_transaction(
    to: recipient_public_key,
    amount: params["amount"]
  )

  transactions.push(transaction)

  message = Message.new(
    port: me.port,
    payload: transaction.to_hash,
    type: Transaction
  )

  send_message_to_peers(
    message: message,
    peers: get_peers(nodes: nodes)
  )

  true
end

get "/public_key" do
  me.public_key.to_text
end

post "/create_block" do
  Utilities::log "I Will Now Create A Block!".cyan
  block = Block.new(
    transactions: transactions,
    previous_block: me.blockchain.last_block
  )
  block.find_matching_nonce

  me.blockchain.add(block: block)
  transactions = []

  message = Message.new(
    port: me.port,
    payload: blockchain.to_hash,
    type: Blockchain
  )

  send_message_to_peers(
    message: message,
    peers: get_peers(nodes: nodes)
  )
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
    check_for_eviction(nodes: nodes)
  end

  if message.type == Transaction
    transaction = Transaction.from_params(params: message.payload)
    transactions.push(transaction)
  elsif message.type = Blockchain
    Utilities::log "RECEIVED NEW BLOCKCHAIN".red
    blockchain = Blockchain.from_params(params: message.payload)
    me.fork_choice(blockchain: blockchain)
  end

  Utilities::log "now my blockchain is:"
  Utilities::log me.blockchain
  Utilities::log "\n\n\n"
end
