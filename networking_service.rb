require_relative "utilities"
require_relative "message"
require_relative "node"

module NetworkingService

  def self.fetch_peers(to:, from:)
    return JSON.parse(
      Utilities::make_request(
        port: to,
        path: "peers",
        body: Message.new(
          port: from
        ).to_hash,
        post: true
      )
    ).map { |params|
      node = Node.from_params(params: params)
      node.is_peer = true
      node
    }.select { |p| p.port != from }
  end

  def self.fetch_public_key(from:)
    Utilities::make_request(
      port: from,
      path: "public_key"
    )
  end

  def self.broadcast_transaction(from:, transaction:, nodes:)
    message = Message.new(
      port: from,
      payload: transaction.to_hash,
      type: Transaction
    )

    Utilities::send_message_to_peers(
      message: message,
      peers: Utilities::get_peers(nodes: nodes)
    )
  end

  def self.broadcast_blockchain(from:, blockchain:, nodes:)
    message = Message.new(
      port: from,
      payload: blockchain.to_hash,
      type: Blockchain
    )

    Utilities::send_message_to_peers(
      message: message,
      peers: Utilities::get_peers(nodes: nodes)
    )
  end

end
