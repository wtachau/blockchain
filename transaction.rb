require_relative "constants"

class Transaction

  attr_accessor :from, :to, :amount, :signature, :is_genesis

  def initialize(from: nil, to: nil, amount: nil, genesis: false)
    @from = from.to_s
    @to = to.to_s
    @amount = amount
    @signature = nil
    @genesis = genesis
  end

  def content_to_sign
    from_content = @from
    if @genesis
      from_content = Constants::GENESIS_KEYWORD
    end

    return "from:#{from_content}|to:#{@to}|amount:#{@amount}"
  end

  def to_s
    return "#{content_to_sign}|signature:#{@signature}"
  end

  def is_genesis?
    @genesis
  end

  def is_valid?
    return true if @genesis
    return false if @signature.nil?

    from.verify(OpenSSL::Digest::SHA256.new, @signature, self.content_to_sign)
  end
end
