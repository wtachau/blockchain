require_relative "networking_service"
require_relative "update_state_service"

module TransferService

  def self.send_money(node:, nodes:, to_port:, amount:, transactions:)
    recipient_public_key = NetworkingService::fetch_public_key(
      from: to_port
    )

    transaction = node.create_transaction(
      to: recipient_public_key,
      amount: amount
    )

    transactions.push(transaction)

    UpdateStateService::share_state(
      from: node,
      transactions: transactions,
      blockchain: node.blockchain
    )

    NetworkingService::broadcast_transaction(
      from: node.port,
      transaction: transaction,
      nodes: nodes
    )
  end

end
