 require "colorize"

require_relative "block"
require_relative "blockchain"
require_relative "constants"
require_relative "node"
require_relative "proof_of_work"
require_relative "transaction"
require_relative "utilities"

def test(description)
  is_true = yield()
  print Utilities::fixed_length(description, 60) + "-> "
  if is_true
    puts "passed".green
  else
    puts "failed".red
  end
end

alice = Node.new(port: 3000)
bob = Node.new(port: 3001)
will = Node.new(port: 3002)

t1 = Transaction.new(from: alice.public_key, to: will.public_key, amount: 10)
t2 = Transaction.new(from: will.public_key, to: bob.public_key, amount: 5 )
t3 = Transaction.new(from: bob.public_key, to: alice.public_key, amount: 3)

block1 = Block.new(
  transactions: [t1],
  previous_block: nil
)

test("transaction is not valid before being signed") {
  !t1.is_valid?
}
test("block is not valid with invalid transaction") {
  !block1.is_valid?
}

alice.sign(transaction: t1)
will.sign(transaction: t2)
bob.sign(transaction: t3)

test("transaction is valid after signature") {
  t1.is_valid?
}

test("block is invalid with valid transaction but missing nonce") {
  !block1.is_valid?
}

block1.find_matching_nonce

test("block is valid with valid transactions and valid nonce") {
  block1.is_valid?
}

block2 = Block.generate(
  transactions: [t2],
  previous_block: block1
)

block3 = Block.generate(
  transactions: [t3],
  previous_block: block2
)

blockchain = Blockchain.new(blocks: [block1, block2, block3])

test("height is right") {
  blockchain.height == 3
}
test("blockchain is invalid if balances go below zero") {
  !blockchain.is_valid?
}

t0 = Transaction.new(to: alice.public_key, amount: 50, genesis: true)

test("genesis transactions need not be signed") {
  t0.is_valid?
}

block0 = Block.generate(
  transactions: [t0],
  previous_block: nil
)

test("new gensis block with genesis transactions valid") {
  block0.is_valid?
}

blockchain = Blockchain.new(blocks: [block0, block1, block2, block3])

test("blockchain with two genesis blocks shouldn't be valid") {
  !blockchain.is_valid?
}

block1.set_previous_block(block: block0)
test("block becomes invalid after setting previous block") {
  !block1.is_valid?
}

block1.find_matching_nonce
test("block re-valid after re-finding nonce") {
  block1.is_valid?
}

test("after re-setting block pointers, blockchain is invalid since block hashes changed") {
  !blockchain.is_valid?
}
block2.set_previous_block(block: block1)
block2.find_matching_nonce
block3.set_previous_block(block: block2)
block3.find_matching_nonce

test("finally, blockchain valid") {
  blockchain.is_valid?
}

puts blockchain
