require_relative "networking_service"
require_relative "block"

module BlockService

  def self.generate_block(node:, nodes:, transactions:)
    block = Block.generate(
      transactions: transactions,
      previous_block: node.blockchain.last_block
    )

    node.blockchain.add(block: block)

    NetworkingService::broadcast_blockchain(
      from: node.port,
      blockchain: node.blockchain,
      nodes: nodes
    )
  end
end
