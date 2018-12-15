require 'openssl'
require 'digest'

require_relative "transaction"

class Node

  attr_accessor :public_key, :sign, :port, :blockchain

  def initialize(port:)
    @port = port

    if File.file?(key_filename)
      @key = OpenSSL::PKey::RSA.new(File.read(key_filename))
    else
      @key = OpenSSL::PKey::RSA.new(2048)
      File.open(key_filename, "w+") do |f|
        f.write @key.to_pem
      end
    end

    @blockchain = nil
  end

  def key_filename
    "#{@port}-key.pem"
  end

  def public_key
    @key.public_key
  end

  def address
    Digest::SHA2.hexdigest(public_key)
  end

  def to_s
    port.to_s
  end

  def create_transaction(to:, amount:)
    transaction = Transaction.new(
      from: public_key,
      to: to,
      amount: amount
    )
    sign(transaction: transaction)
    return transaction
  end

  def sign(transaction:)
    transaction.signature = @key.sign(OpenSSL::Digest::SHA256.new, transaction.content_to_sign)
  end

  # def verify(signature:, transaction:)
  #   return false if signature.nil?
  #   @key.public_key.verify(OpenSSL::Digest::SHA256.new, signature, transaction.content_to_sign)
  # end

  def fork_choice(blockchain:)
    return if !blockchain.is_valid?

    if @blockchain.nil? || blockchain.height > @blockchain.height
      @blockchain = blockchain
    end
  end
end
