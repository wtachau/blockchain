require_relative "constants"
require_relative "transaction"
require_relative "block"
require_relative "blockchain"

module BlockchainConfig

  def self.generate_initial_block
    return Block.new(
      transactions: [
        Transaction.new(
          to: Node.new(
            port: Constants::INITIAL_MONEY_PORT
          ).public_key,
          amount: Constants::INITIAL_MONEY_AMOUNT,
          genesis: true
        )
      ]
    )
  end

  def self.generate_initial_blockchain
    genesis_block = generate_initial_block

    # If it exists, load an appropriate nonce from disk
    if File.file?(Constants::GENESIS_BLOCK_NONCE_FILENAME)
      genesis_block.nonce = Marshal.load(
        File.binread(Constants::GENESIS_BLOCK_NONCE_FILENAME)
      )
    end

    # If it doesn't exist, or if the block has changed (now making
    #  the nonce invalid), find another nonce and write it to disk
    #  for future use
    if genesis_block.nonce.nil? || !genesis_block.is_valid?
      genesis_block.find_matching_nonce

      File.open(Constants::GENESIS_BLOCK_NONCE_FILENAME, 'wb') { |f|
        f.write(Marshal.dump(genesis_block.nonce))
      }
    end

    return Blockchain.new(blocks: [genesis_block])
  end

end
