require_relative "constants"
require_relative "utilities"
require_relative "proof_of_work"
require_relative "merkle_tree"

class Block
  attr_accessor :transactions, :previous_hash, :nonce, :block_header, :has_valid_nonce, :has_valid_transactions

  def initialize(transactions: nil, previous_block: nil, nonce: nil)
    @transactions = transactions.dup
    @merkle_tree = MerkleTree.new(data: @transactions.map(&:to_s))
    if previous_block && !previous_block.is_valid?
      raise "Cannot instantiate block with invalid previous block"
    end
    @previous_hash = previous_block ? previous_block.hash : Constants::GENESIS_KEYWORD
    @nonce = nonce
  end

  def self.generate(transactions:, previous_block:)
    block = self.new(
      transactions: transactions,
      previous_block: previous_block
    )
    block.find_matching_nonce
    return block
  end

  def set_previous_block(block:)
    @previous_hash = block.hash
  end

  def block_header
    "#{@merkle_tree.root_node_hash}||#{@previous_hash}"
  end

  def hash
    Digest::SHA2.hexdigest("#{block_header}||#{@nonce}")
  end

  def is_valid?
    return false if @nonce.nil?
    return has_valid_nonce && has_valid_transactions
  end

  def has_valid_nonce
    return ProofOfWork::verify_proof_of_work(block_header, Constants::WORK_FACTOR, @nonce)
  end

  def has_valid_transactions
    return @transactions.all? { |t| t.is_valid? }
  end

  def find_matching_nonce
    @nonce = ProofOfWork::generate_proof_of_work(
      challenge: self.block_header,
      work_factor: Constants::WORK_FACTOR
    )
  end

  def to_hash
    {
      transactions: @transactions.map(&:to_hash),
      previous_hash: @previous_hash,
      merkle_root: @merkle_tree.root_node_hash,
      nonce: @nonce,
      hash: self.hash
    }.with_indifferent_access
  end

  def self.from_params(params:)
    block = self.new(
      transactions: params["transactions"].map { |transaction_params|
        Transaction.from_params(params: transaction_params)
      },
      nonce: params["nonce"]
    )
    block.previous_hash = params["previous_hash"]
    block
  end

  def to_s
    (
      "           BLOCK\n".light_blue +
      " +-----------------------+\n" +
      " | PREVIOUS HASH POINTER |\n" +
      " | " + "#{Utilities::fixed_length(@previous_hash, 21)}".cyan + " |\n" +
      " +-----------------------+\n" +
      " |      TRANSACTIONS     |\n" +
      @transactions.map(&:friendly_string).join("\n") +
      " |        NONCE          |\n" +
      " | " + "#{Utilities::fixed_length(@nonce, 21)}".magenta + " |\n" +
      " +-----------------------+\n" +
      " |         HASH          |\n" +
      " | " + "#{Utilities::fixed_length(self.hash, 21)}".red + " |\n" +
      " +-----------------------+"
    ).force_encoding("UTF-8")
  end
end
