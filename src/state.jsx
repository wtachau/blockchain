import React from 'react'
import ReactDOM from 'react-dom'

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

  nodeDisplay = (data) => {
    console.log(data)
    return (
      <div>
        <div>
          <div>blockchain:</div>
          <div>
            {data.blockchain.blocks.length}
          </div>
        </div>
        <div>
          <div>mempool:</div>
          <div>
            {data.transactions.length}
          </div>
        </div>
      </div>
    )
  }

  render = () => {
    const { data } = this.state

    const toPrint = Object.keys(data).map((key) => {
      return (
        <div>
          <div>{key}</div>
          <div>{this.nodeDisplay(data[key])}</div>
        </div>
      )
    })
    return <div>{toPrint}</div>
  }
}

ReactDOM.render(
  <Blockchain/>,
  container
);
