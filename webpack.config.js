const path = require('path')

module.exports = {
  entry: {
    index: [
      './src/state_compiled.js',
    ]
  },
  resolve: {
    modules: [
      './src',
      'node_modules'
    ]
  },
  module: {
    rules: [
      {
        use: 'babel-loader',
        test: /\.js$/,
        exclude: /node_modules/
      }
    ]
  },
  output: {
    path: path.resolve(__dirname, './public'),
    filename: '[name].bundle.js',
    publicPath: '/'
  }
}
