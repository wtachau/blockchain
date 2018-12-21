require 'active_support/core_ext/hash/indifferent_access'
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
    if !block.is_valid?
      Utilities::log block
      raise ("cannot add invalid block")
    end

    @blocks.push(block)
  end

  def balances_sufficient?
    balances = {}
    @blocks.each do |block|
      block.transactions.each do |transaction|

        # First check that sender has enough
        if !transaction.is_genesis?
          sender = Digest::SHA2.hexdigest(transaction.from.to_s)

          if balances[sender].nil? || balances[sender] < transaction.amount
            Utilities.log "#{sender} only has #{balances[sender]} but is sending #{transaction.amount}".red
            return false, balances
          end

          balances[sender] -= transaction.amount
        end

        receiver = Digest::SHA2.hexdigest(transaction.to.to_s)
        balances[receiver] ||= 0
        balances[receiver] += transaction.amount
      end
    end

    return true, balances
  end

  def all_blocks_valid?
    @blocks.all? { |b| b.is_valid? }
  end

  def blocks_sequential?
    previous_block = nil
    return @blocks.all? { |b|
      matches = true
      # don't check if this is the first block
      if previous_block
        matches = b.previous_hash == previous_block.hash
      end
      previous_block = b
      matches
    }
  end

  def is_valid?
    balances_sufficient, _ = balances_sufficient?
    return all_blocks_valid? && blocks_sequential? && balances_sufficient
  end

  def to_hash
    return {
      blocks: @blocks.map(&:to_hash)
    }.with_indifferent_access
  end

  def self.from_params(params:)
    return self.new(
      blocks: params["blocks"].map { |block_params|
        Block.from_params(params: block_params)
      }
    )
  end
end
