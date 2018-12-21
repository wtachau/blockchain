require_relative "utilities"
require_relative "constants"

module UpdateStateService

  def self.share_state(from:, transactions:, blockchain:)
    _, balances = blockchain.balances_sufficient?

    Utilities::make_request(
      port: Constants::STATE_SERVICE_PORT,
      path: "/state",
      body: {
        from: from.port,
        state: {
          port: from.port,
          transactions: transactions.map(&:to_hash),
          blockchain: blockchain.to_hash,
          balances: balances
        }
      },
      post: true
    )
  end
end

