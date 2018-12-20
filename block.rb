require_relative "constants"
require_relative "utilities"
require_relative "proof_of_work"

class Block
  attr_accessor :transactions, :previous_hash, :nonce, :content_to_validate

  def initialize(transactions: nil, previous_block: nil, nonce: nil)
    @transactions = transactions
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

  def content_to_validate
    transactions_content = @transactions.map(&:to_s).join("||")
    "#{transactions_content}||#{@previous_hash}"
  end

  def hash
    Digest::SHA2.hexdigest("#{content_to_validate}||#{@nonce}")
  end

  def is_valid?
    return false if @nonce.nil?

    nonce_is_valid = ProofOfWork::verify_proof_of_work(content_to_validate, Constants::WORK_FACTOR, @nonce)
    transactions_are_valid = @transactions.all? { |t| t.is_valid? }

    return nonce_is_valid && transactions_are_valid
  end

  def find_matching_nonce
    @nonce = ProofOfWork::generate_proof_of_work(
      challenge: self.content_to_validate,
      work_factor: Constants::WORK_FACTOR
    )
  end

  def to_hash
    {
      transactions: @transactions.map(&:to_hash),
      previous_hash: @previous_hash,
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
