require_relative "networking_service"

module TransferService

  def self.send_money(node:, nodes:, to_port:, amount:)
    recipient_public_key = NetworkingService::fetch_public_key(
      from: to_port
    )

    transaction = node.create_transaction(
      to: recipient_public_key,
      amount: amount
    )

    NetworkingService::broadcast_transaction(
      from: node.port,
      transaction: transaction,
      nodes: nodes
    )

    return transaction
  end

end
