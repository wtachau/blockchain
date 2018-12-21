require 'digest'

require_relative "utilities"

class MerkleTree

  attr_accessor :root_node_hash

  def initialize(data:)
    if Utilities::is_power_of_two(number: data.count)
      leaves_data = data
    else
      # Fill in extra leaves with 0s
      number_extra_leaves = Utilities::next_highest_power_of_two(
        number: data.count
      ) - data.count
      extra_leaves = Array.new(number_extra_leaves, "0")
      leaves_data = data.concat(extra_leaves)
    end

    @leaves = data.map { |d| MerkleBlock.new(data: d) }
    @root_node = calculate_root_node
  end

  def calculate_root_node
    next_layer = []
    last_layer = @leaves

    while last_layer.count > 1
      last_layer.each_slice(2) do |left, right|
        new_block = MerkleBlock.new(left_node: left, right_node: right)
        next_layer.push(new_block)
      end

      last_layer = next_layer
      next_layer = []
    end

    @root_node = last_layer[0]
  end

  def root_node_hash
    @root_node.hash
  end

  def print()
    puts "\n"
    @root_node.print(0)
  end
end

class MerkleBlock
  attr_accessor :hash, :data, :left_node, :right_node

  def initialize(data: nil, left_node: nil, right_node: nil)
    @data = data
    @left_node = left_node
    @right_node = right_node
    @hash = calculate_hash
  end

  def calculate_hash
    if @data
      return Digest::SHA2.hexdigest(@data)
    else
      return Digest::SHA2.hexdigest("#{@left_node.hash}||#{@right_node.hash}")
    end
  end

  def print(layers)
    indent = "\t" * layers + " > "
    puts indent + @hash
    if @data
      puts indent + "\t" + @data
    else
      @left_node.print(layers + 1)
      @right_node.print(layers + 1)
    end
  end
end


# blocks = [
#   "We", "hold", "these", "truths", "to", "be", "self-evident", "that", "extra"
# ]

# tree = MerkleTree.new(data: blocks)

# tree.print()
