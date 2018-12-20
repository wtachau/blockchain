require_relative "utilities"
require_relative "transaction"
require_relative "blockchain"

module MessageService

  def self.should_not_process(message:, recent_messages:, me:)
    if recent_messages.include? message.uuid
      Utilities::log "Seen message #{message.uuid} before, ignoring".red
      return true
    end
    recent_messages.add(message.uuid)

    if message.port == me.port
      Utilities::log "Message is from me, ignoring".red
      return true
    end

    return false
  end

  def self.handle_message(message:, transactions:, me:, nodes:)
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

    # Pass on message, if appropriate
    message.ttl -= 1

    if message.ttl > 0
      Utilities::send_message_to_peers(
        message: message,
        peers: Utilities::get_peers(nodes: nodes)
      )
    end

    Utilities::log "now my blockchain is:"
    Utilities::log me.blockchain
    Utilities::log "\n\n\n"
  end
end


