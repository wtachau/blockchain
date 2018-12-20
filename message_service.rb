require_relative "utilities"
require_relative "transaction"
require_relative "blockchain"

module MessageService

  def self.have_already_received(message:, recent_messages:)
    if recent_messages.include? message.uuid
      Utilities::log "Seen message #{message.uuid} before, ignoring".red
      return true
    end
    recent_messages.add(message.uuid)

    return false
  end

  def self.handle_message(message:, transactions:, me:)
    Utilities::log "RECEIVED MESSAGE".blue.on_red.blink
    Utilities::log (message.type.to_s.magenta + "\t" + message.uuid.green)

    if message.type == Transaction
      transaction = Transaction.from_params(params: message.payload)
      if transaction.is_valid?
        transactions.push(transaction)
      else
        Utilities::log "Will not add invalid transaction!".red
      end
    elsif message.type == Blockchain
      Utilities::log "RECEIVED NEW BLOCKCHAIN".red
      blockchain = Blockchain.from_params(params: message.payload)
      me.fork_choice(blockchain: blockchain)
      transactions.clear
    end

    Utilities::log "now my blockchain is:"
    Utilities::log me.blockchain
    Utilities::log "\n\n\n"
  end
end


