// Import the page's CSS. Webpack will know what to do with it.
import '../css/style.css'

// Import libraries we need.
import { default as Web3 } from 'web3'
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
import gobangArtifact from '../../build/contracts/Gobang.json'

// Gobang is our usable abstraction, which we'll use through the code below.
const Gobang = contract(gobangArtifact)

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.

let canvas = document.getElementById('chess')
let context = canvas.getContext('2d')
let me = true // 判断该轮黑白棋落子权
let over = false // 判断游戏是否结束
let chessBoard = [] // 棋盘二维数组,存储棋盘信息
let isPlaying = false // 是否正在进行游戏
let timeout // 间隔请求状态的时间

const App = {
  start: function () {
    // 初始化棋盘信息
    for (var i = 0; i < 15; i++) {
      chessBoard[i] = []
      for (var j = 0; j < 15; j++) {
        chessBoard[i][j] = 0
      }
    }

    // Bootstrap the Gobang abstraction for Use.
    Gobang.setProvider(web3.currentProvider)

    Gobang.deployed().then(function (instance) {
      window.gobang = instance
      console.log(window.gobang)
    })
  },

  joinGame: function () {
    let self = this

    window.gobang.joinGame({
      from: web3.eth.accounts[0]
    }).then(function (re) {
      self.cleanChess()
      self.drawChess()
      self.setStatus('Transaction complete!')
      console.log('joinGame:' + re)

      timeout = setInterval(function () {
        self.getNewestState()
      }, 3000)
    })
      .catch(function (e) {
        console.log(e)
      // self.setStatus('Error sending coin; see log.')
      })
  },

  getNewestState: function () {
    window.gobang.getNewestState({ from: web3.eth.accounts[0] })
      .then(function (re) {
        console.log('getNewestState:' + re)
        if (!isPlaying) {
        // 清除循环执行
          clearInterval(timeout)
        }
      }).then(function (data) {
        console.log('getNewestState:' + data)
      // self.setStatus('Transaction complete!')
      }).catch(function (e) {
        console.log(e)
      // self.setStatus('Error sending coin; see log.')
      })
  },

  setStatus: function (message) {
    const status = document.getElementById('status')
    status.innerHTML = message
  },

  /**
     * 清除棋盘
     */
  cleanChess: function () {
    context.fillStyle = '#FFFFFF'
    context.fillRect(0, 0, canvas.width, canvas.height)
  },

  /**
     * 绘制棋盘
     */
  drawChess: function () {
    for (let i = 0; i < 15; i++) {
      context.strokeStyle = '#BFBFBF'
      context.beginPath()
      context.moveTo(15 + i * 30, 15)
      context.lineTo(15 + i * 30, canvas.height - 15)
      context.closePath()
      context.stroke()
      context.beginPath()
      context.moveTo(15, 15 + i * 30)
      context.lineTo(canvas.width - 15, 15 + i * 30)
      context.closePath()
      context.stroke()
    }
  },

  /**
     * 绘制棋子
     * @param i     棋子x轴位置
     * @param j     棋子y轴位置
     * @param me    棋子颜色
     */
  oneStep: function (i, j, me) {
    context.beginPath()
    context.arc(15 + i * 30, 15 + j * 30, 13, 0, 2 * Math.PI)
    context.closePath()
    let gradient = context.createRadialGradient(15 + i * 30 + 2, 15 + j * 30 - 2,
      13, 15 + i * 30 + 2, 15 + j * 30 - 2, 0)
    if (me) {
      gradient.addColorStop(0, '#D1D1D1')
      gradient.addColorStop(1, '#F9F9F9')
    } else {
      gradient.addColorStop(0, '#0A0A0A')
      gradient.addColorStop(1, '#636766')
    }
    context.fillStyle = gradient
    context.fill()
  }
}

window.App = App

window.addEventListener('load', function () {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn(
      'Using web3 detected from external source.' +
            ' If you find that your accounts don\'t appear or you have 0 Gobang,' +
            ' ensure you\'ve configured that source properly.' +
            ' If using MetaMask, see the following link.' +
            ' Feel free to delete this warning. :)' +
            ' http://truffleframework.com/tutorials/truffle-and-metamask'
    )
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider)
  } else {
    console.warn(
      'No web3 detected. Falling back to http://127.0.0.1:9545.' +
            ' You should remove this fallback when you deploy live, as it\'s inherently insecure.' +
            ' Consider switching to Metamask for development.' +
            ' More info here: http://truffleframework.com/tutorials/truffle-and-metamask'
    )
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'))
  }

  App.start()
})

/**
 * canvas 鼠标点击事件
 * @param e
 */
canvas.onclick = function (e) {
  if (over) {
    return
  }

  let x = e.offsetX
  let y = e.offsetY
  let i = Math.floor(x / 30)
  let j = Math.floor(y / 30)

  // 如果该位置没有棋子,则允许落子
  if (chessBoard[i][j] === 0) {
    // 绘制棋子(玩家)
    App.oneStep(i, j, me)
    // 改变棋盘信息(该位置有棋子)
    chessBoard[i][j] = 1
  }
}
