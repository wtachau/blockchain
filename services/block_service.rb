require_relative "../utilities"

require_relative "networking_service"
require_relative "update_state_service"

require_relative "../models/block"

module BlockService

  def self.generate_block(node:, nodes:, transactions:)
    block = Block.generate(
      transactions: transactions,
      previous_block: node.blockchain.last_block
    )

    if !block.is_valid?
      Utilities::log "Not adding block or broadcasting because it is invalid".red
      return false

      # TODO: If it's invalid, try again with different transactions
    end

    node.blockchain.add(block: block)
    transactions.clear

    UpdateStateService::share_state(
      from: node,
      transactions: transactions,
      blockchain: node.blockchain
    )

    NetworkingService::broadcast_blockchain(
      from: node.port,
      blockchain: node.blockchain,
      nodes: nodes
    )

    return true
  end
end
