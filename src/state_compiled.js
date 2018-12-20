"use strict";

var _react = _interopRequireDefault(require("react"));

var _reactDom = _interopRequireDefault(require("react-dom"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { if (typeof Symbol === "function" && typeof Symbol.iterator === "symbol") { _typeof = function _typeof(obj) { return typeof obj; }; } else { _typeof = function _typeof(obj) { return obj && typeof Symbol === "function" && obj.constructor === Symbol && obj !== Symbol.prototype ? "symbol" : typeof obj; }; } return _typeof(obj); }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (call && (_typeof(call) === "object" || typeof call === "function")) { return call; } return _assertThisInitialized(self); }

function _getPrototypeOf(o) { _getPrototypeOf = Object.setPrototypeOf ? Object.getPrototypeOf : function _getPrototypeOf(o) { return o.__proto__ || Object.getPrototypeOf(o); }; return _getPrototypeOf(o); }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function"); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, writable: true, configurable: true } }); if (superClass) _setPrototypeOf(subClass, superClass); }

function _setPrototypeOf(o, p) { _setPrototypeOf = Object.setPrototypeOf || function _setPrototypeOf(o, p) { o.__proto__ = p; return o; }; return _setPrototypeOf(o, p); }

function _assertThisInitialized(self) { if (self === void 0) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return self; }

function _defineProperty(obj, key, value) { if (key in obj) { Object.defineProperty(obj, key, { value: value, enumerable: true, configurable: true, writable: true }); } else { obj[key] = value; } return obj; }

var createElement = _react.default.createElement;
var container = document.getElementById('react_root');

var Blockchain =
/*#__PURE__*/
function (_React$Component) {
  _inherits(Blockchain, _React$Component);

  function Blockchain() {
    var _this;

    _classCallCheck(this, Blockchain);

    _this = _possibleConstructorReturn(this, _getPrototypeOf(Blockchain).call(this));

    _defineProperty(_assertThisInitialized(_assertThisInitialized(_this)), "componentWillMount", function () {
      var socket = new WebSocket('ws://' + window.location.host + window.location.pathname);

      socket.onmessage = function (m) {
        var data = JSON.parse(m.data);

        _this.setState({
          data: data
        });
      };
    });

    _defineProperty(_assertThisInitialized(_assertThisInitialized(_this)), "nodeDisplay", function (data) {
      console.log(data);
      return _react.default.createElement("div", null, _react.default.createElement("div", null, _react.default.createElement("div", null, "blockchain:"), _react.default.createElement("div", null, data.blockchain.blocks.length)), _react.default.createElement("div", null, _react.default.createElement("div", null, "mempool:"), _react.default.createElement("div", null, data.transactions.length)));
    });

    _defineProperty(_assertThisInitialized(_assertThisInitialized(_this)), "render", function () {
      var data = _this.state.data;
      var toPrint = Object.keys(data).map(function (key) {
        return _react.default.createElement("div", null, _react.default.createElement("div", null, key), _react.default.createElement("div", null, _this.nodeDisplay(data[key])));
      });
      return _react.default.createElement("div", null, toPrint);
    });

    _this.state = {
      data: []
    };
    return _this;
  }

  return Blockchain;
}(_react.default.Component);

_reactDom.default.render(_react.default.createElement(Blockchain, null), container);
