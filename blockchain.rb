require "colorize"
require "securerandom"
require "digest"

require_relative "block"
require_relative "constants"
require_relative "node"
require_relative "proof_of_work"
require_relative "transaction"
require_relative "utilities"

class Blockchain

  attr_accessor :blocks

  def initialize(blocks: nil)
    @blocks = blocks
  end

  def to_s
    @blocks.map(&:to_s).join("\n---------------------------\n")
  end

  def height
    @blocks.count
  end

  def last_block
    @blocks.last
  end

  def add(block:)
    @blocks.push(block)
  end


  def balances_sufficient
    balances = {}
    @blocks.each do |block|
      block.transactions.each do |transaction|
        # First check that sender has enough
        if !transaction.is_genesis?
          sender = transaction.from.to_s

          balances[sender] ||= 0

          if balances[sender] < transaction.amount
            # puts "#{sender} only has #{balances[sender]} but is sending #{transaction.amount}"
            return false
          end
        end

        receiver = transaction.to.to_s
        balances[receiver] ||= 0
        balances[receiver] += transaction.amount
      end
    end
  end

  def is_valid?
    blocks_valid = @blocks.all? { |b| b.is_valid? }

    previous_block = nil
    blocks_sequential = @blocks.all? { |b|
      matches = true
      # don't check if this is the first block
      if previous_block
        matches = b.previous_hash == previous_block.to_hash
      end
      previous_block = b
      matches
    }

    return blocks_valid && blocks_sequential && balances_sufficient
  end
end
