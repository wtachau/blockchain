require "sinatra"
require "sinatra-websocket"
require "colorize"
require "httparty"
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
    log "Sending message #{message.uuid} to port #{peer.port}".light_blue

    make_request(
      url: "http://localhost:#{peer.port}/gossip",
      body: message.to_hash,
      post: true
    )
  end
end

def check_for_eviction(nodes:)
  peers = get_peers(nodes: nodes)
  if peers.count > MAX_PEERS_COUNT
    peer_to_remove = peers.sample
    peer_to_remove.is_peer = false
  end
end

def log(string)
  puts "[#{Time.now}] " + string
end

nodes = []
seed_port = ARGV[0]
if seed_port && seed_port != "-p"

  peers_response = make_request(
    url: "http://localhost:#{seed_port}/peers",
    body: Message.new(
      port: me.port
    ).to_hash,
    post: true
  )

  nodes = JSON.parse(peers_response).map { |params|
    node = Node.from_params(params: params)
    node.is_peer = true
    node
  }
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

if File.file?(Constants::GENESIS_BLOCK_NONCE_FILENAME)
  genesis_block.nonce = Marshal.load(File.binread(Constants::GENESIS_BLOCK_NONCE_FILENAME))
  puts "Getting from file"
end

if genesis_block.nonce.nil? || !genesis_block.is_valid?
  puts "creating, writing to file"
  genesis_block.find_matching_nonce

  File.open(Constants::GENESIS_BLOCK_NONCE_FILENAME, 'wb') { |f|
    f.write(Marshal.dump(genesis_block.nonce))
  }
end

blockchain = Blockchain.new(blocks: [genesis_block])

recent_messages = Set.new
transactions = []
me = Node.new(port: settings.port)
me.fork_choice(blockchain: blockchain)

# puts Marshal.dump(blockchain)

log "Node #{settings.port} coming online".green

post "/peers" do
  params = JSON.parse(request.body.read)
  message = Message.from_params(params: params)
  node = nodes.find { |node| node.port == message.port }

  if node
    if node.version < message.version
      node.version = message.version
      node.book = message.payload
      node.last_heard_from = Time.now
    end
  else
    new_node = Node.new(
      port: message.port,
      book: message.payload,
      version: message.version,
      is_peer: true
    )
  end

  (get_peers(nodes: nodes) + [me]).map(&:to_hash).to_json
end

post "/transfer" do
  params = JSON.parse(request.body.read)

  recipient_public_key = Utilities::make_request(url: "http://localhost:#{params['to']}/public_key")

  transaction = me.create_transaction(
    to: recipient_public_key,
    amount: params["amount"]
  )

  transactions.push(transaction)
  puts transactions.map(&:friendly_string)

  message = Message.new(
    port: me.port,
    payload: Marshal.dump(transaction)
  )
  send_message_to_peers(
    message: message,
    peers: get_peers(nodes: nodes)
  )
  true
end

get "/public_key" do
  puts "looking up"
  puts me.public_key
  return me.public_key.to_text
end

post "/create_block" do

  block = Block.new(
    transactions: transactions,
    previous_block: me.blockchain.last_block
  )
  block.find_matching_nonce

  me.blockchain.add(block: block)

  puts me.blockchain
end
