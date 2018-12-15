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

  def friendly_string
    from_string = Constants::GENESIS_KEYWORD
    if self.from
      from_string = Digest::SHA2.hexdigest(self.from.to_s)
    end
    to_string = Digest::SHA2.hexdigest(self.to_s)

    return " | FROM: #{Utilities::fixed_length(from_string, 15)} |\n" +
    " | TO: #{Utilities::fixed_length(to_string, 17)} |\n" +
    " | AMOUNT: #{Utilities::fixed_length(self.amount.to_s, 13)} |\n" +
    " | SIGNATURE: #{Utilities::fixed_length(self.signature, 11)} |\n" +
    " +-----------------------+\n"
  end

  def is_genesis?
    @genesis
  end

  def is_valid?
    return true if @genesis
    return false if @signature.nil?

    from_public_key = OpenSSL::PKey::RSA.new(from)

    from_public_key.public_key.verify(OpenSSL::Digest::SHA256.new, @signature, self.content_to_sign)
  end
end
