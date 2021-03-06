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

  row = (label, value) => {
    return (
      <div className='row'>
        <div className='label'>
          {label}
        </div>
        <div className='value'>
          {value}
        </div>
      </div>
    )
  }

  blockDisplay = (block) => {
    const { previous_hash, merkle_root, timestamp, nonce, hash } = block
    return (
      <div className='block'>
        { this.row('previous_hash', previous_hash) }
        { this.row('merkle_root', merkle_root) }
        { this.row('timestamp', timestamp) }
        { this.row('nonce', nonce) }
        { this.row('hash', hash) }
      </div>
    )
  }

  transactionDisplay = (transaction) => {
    const { from, to, amount, signature } = transaction

    return (
      <div className='transaction'>
        { this.row('from', sha256(from))}
        { this.row('to', sha256(to))}
        { this.row('amount', '$' + amount)}
        { this.row('signature', String.fromCharCode.apply(null, signature))}
      </div>
    )
  }

  nodeDisplay = (data) => {
    console.log(data)
    if (!data) {
      return null
    }
    return (
      <div className="node">
        <div className="node-contents">
          <div className='port'> PORT {data.port} </div>

          <div>
            <div className='balances-header'>
              balances:
            </div>
          </div>

          <div className='balances'>
            {
              Object.keys(data.balances).map((balanceKey) => {
                return this.row(balanceKey, (" => $") + data.balances[balanceKey])
              })
            }
          </div>

          <div>
            <div className='blockchain-header'>
              blockchain height: <b>{data.blockchain.blocks.length} blocks</b>
            </div>
          </div>

          <div className='blocks'>
            {
              data.blockchain.blocks.map((block) => {
                return this.blockDisplay(block);
              }).reduce((prev, curr) => [prev, <div className='separator'> ^ </div>, curr])
            }
          </div>

          <div>
            <div className='transactions-header'>
              mempool size: <b>{data.transactions.length}</b>
            </div>
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
    const numPerRow = 4;
    for (var i = 0; i < keys.length + 3; i += numPerRow) {
      nodeDisplays.push(
        <div className='node-row clearfix'>
          { this.nodeDisplay(data[keys[i]])}
          { this.nodeDisplay(data[keys[i + 1]])}
          { this.nodeDisplay(data[keys[i + 2]])}
          { this.nodeDisplay(data[keys[i + 3]])}
        </div>
      )
    }
    return (
      <div>
        <h1>WillCoin</h1>
        {nodeDisplays}
      </div>
    )
  }
}

ReactDOM.render(
  <Blockchain/>,
  container
);
