# WillCoin
## A Rudimentary (But Lucrative) Cryptocurrency

This Cryptocurrency, soon to be valued at $1 Billion, is an illustration of many concepts that make up the very promising and newsworthy Blockchain technology.

<img width="1439" alt="screen shot 2018-12-20 at 11 36 33 pm" src="https://user-images.githubusercontent.com/3579673/50330727-294ac800-04b1-11e9-8b7f-7c953cb6964d.png">

## Will This Make Me Rich?
No.

## Can I Learn From This?
Maybe.

## What is this?
This is a barebones implementation of a cryptocurrency, which includes the following features:
* The creation of a Transaction (from a "sender" entity, to a "recipient" entity, with a certain amount)
* The "signing" of a Transaction from the sender, using [asymmetric cryptography](https://en.wikipedia.org/wiki/Public-key_cryptography)
* The broadcast of the Transaction, using a [gossip protocol](https://en.wikipedia.org/wiki/Gossip_protocol) to many peers
* The packaging of the Transaction, along with several others, into a "Block." The "Block" contains:
  * A [Merkle Tree](https://en.wikipedia.org/wiki/Merkle_tree) of Transactions. This is a [very clever] compression technique, such that, for any given set of data, one needs only broadcast the root node of the Merkle Tree. Then, if any client wishes to fetch the rest of the data, the root node is enough information to verify that the later data provided is correct.
  * A reference to the hash of the previous Block. This provides a strict ordering to Blocks, and guarantees that, for any given Block, the shared history is the same. A chain of these blocks leads to, you guessed it, a [Blockchain](https://www.youtube.com/watch?v=dQw4w9WgXcQ).
  * A [nonce](https://en.wikipedia.org/wiki/Cryptographic_nonce), that, used as a suffix to the rest of the block, makes it so that the [hash](https://en.wikipedia.org/wiki/SHA-2) of the block begins with a certain number of zeroes. A nonce that satisfies this criteria is hard to find (exponentially so, depending on the number of zeroes) and therefore makes up the [Proof of Work](https://en.wikipedia.org/wiki/Proof-of-work_system) -- it is a solution to a problem that is easy to verify but hard to generate.
* The broadcast of the new Block, appended to the rest of the Blockchain, again using the gossip protocol. When a node hears a new Blockchain from one of its peers, it will adopt it as its own provided that 1) the Blockchain is valid and 2) its height (the number of blocks in the chain) is greater.

### What is missing?
As a proof-of-concept, this is missing many features. A few of those include:
* The ability for nodes to constantly be mining (right now, mining difficulty is low, and nodes mine a block when they are told to).
* Fault tolerance. Specifically, it does not handle:
  * Nodes coming off and online.
  * Nodes broadcasting invalid transactions (they will not be added to the Blockchain, but the system doesn't recover.)
* Currently, when nodes accept a new block, they clear all the Transactions in their mempool. Instead, they should figure out which transactions were included in the block, and only remove those from the mempool.

 
### How do I run this?
There are two servers in this project: a lightweight UI server, and the main blockchain server. Each node will run its own blockchain server; the UI server only needs to be run once.

To start up the UI server, run:
```rb
ruby state_server.rb
```
To start up a node, run:
```rb
ruby server.rb [SEED_PORT] -p [PORT]
```
The `SEED_PORT` argument is used for discoverability within the gossip protocol -- it tells the new node `A` about an existing node `B` in the system, and `A` can ask `B` about a number of other nodes in the system.
For example, to start up the original node on 3000 and one subsequent node that runs on 3001, run
```rb
ruby server.rb -p 3000
ruby server.rb 3000 -p 3001
```

The system is hardcoded to provide the node on port 3000 with $1000 WillCoin initially, and assumes the UI server is run on port 3010. Those values can be changed in `constants.rb`.


  
[TODO]
