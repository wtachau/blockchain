import React from 'react'
import ReactDOM from 'react-dom'
import sha256 from 'js-sha256'

const { createElement } = React

const container = document.getElementById('react_root')

class Blockchain extends React.Component {
  constructor() {
    super()
    this.state = {
      data: []
    }
  }

  componentWillMount = () => {
    const socket = new WebSocket('ws://' + window.location.host + window.location.pathname)
    socket.onmessage = (m) => {
      var data = JSON.parse(m.data)
      this.setState({ data })
    }
  }

  blockDisplay = (block) => {
    return (
      <div className='block'>
        <div className='previous_hash'>previous_root: {block.previous_hash}</div>
        <div className='merkle_root'> merkle root: TODO </div>
        <div className='nonce'> nonce: {block.nonce} </div>
        <div className='hash'> hash: {block.hash} </div>
      </div>
    )
  }

  transactionDisplay = (transaction) => {
    return (
      <div className='transaction'>
        <div className='from'>from: {sha256(transaction.from)}</div>
        <div className='to'>to: {sha256(transaction.to)}</div>
        <div className='amount'>amount: ${transaction.amount}</div>
        <div className='signature'>signature: ${String.fromCharCode.apply(null, transaction.signature)}</div>
      </div>
    )
  }

  nodeDisplay = (data) => {
    if (!data) {
      return null
    }
    console.log(data)
    return (
      <div className="node">
        <div className="node-contents">
          <div> port: {data.port} </div>
          <div>
            <div>blockchain height: {data.blockchain.blocks.length} blocks</div>
          </div>

          <div className='blocks'>
            {
              data.blockchain.blocks.map((block) => {
                return this.blockDisplay(block);
              })
            }
          </div>

          <div>
            <div>mempool size: {data.transactions.length}</div>
          </div>

          <div className='transactions'>
            {
              data.transactions.map((transaction) => {
                return this.transactionDisplay(transaction)
              })
            }
          </div>
        </div>
      </div>
    )
  }

  render = () => {
    const { data } = this.state

    const keys = Object.keys(data)

    const nodeDisplays = []
    for (var i = 0; i < keys.length + 2; i += 3) {
      nodeDisplays.push(
        <div className='node-row clearfix'>
          { this.nodeDisplay(data[keys[i]])}
          { this.nodeDisplay(data[keys[i + 1]])}
          { this.nodeDisplay(data[keys[i + 2]])}
        </div>
      )
    }
    return <div>{nodeDisplays}</div>
  }
}

ReactDOM.render(
  <Blockchain/>,
  container
);
