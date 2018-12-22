require "json"
require_relative "utilities"

module Client

  def self.transfer(from:, to:, amount:)
    Utilities::make_request(
      port: from,
      path: "/transfer",
      body: {
        to: to,
        amount: amount
      },
      post: true
    )
  end

  def self.create_block(port:)
    Utilities::make_request(
      port: port,
      path: "/create_block",
      post: true
    )
  end

end
