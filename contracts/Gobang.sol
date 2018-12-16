pragma solidity ^0.4.23;


contract Gobang {
    address[2] public players;
    //是哪个选手的轮次
    uint8 playerTurn;

    uint128 BET_MONEY = 1 ether;

    //游戏状态：0-未开始，1-游戏中，2-已结束
    enum GameStatus {start, playing, over}
    GameStatus playStatus;

    uint constant boardSize = 15;

    uint8[boardSize][boardSize] chessboard;

    //统计棋子的数量
    uint8 stone_num;

    uint8 winner;

    mapping (address => uint128) playersMoney;


    event OneStep(uint8 x, uint8 y);

    event GameOver(uint8 winner);

    constructor() public {
        players[0] = 0x0;
        players[1] = 0x0;
        playerTurn = 0;
        playStatus = GameStatus.start;
        winner = 0;
    }

    //加入游戏
    function joinGame() public payable {
        require(players[0] == 0x0 || players[1] == 0x0, "Can not join game");
        require(msg.value >= BET_MONEY);
        if (players[0] == 0x0) {
            players[0] = msg.sender;
        }
        else if (players[1] == 0x0) {
            players[1] = msg.sender;
        }
        if (players[0] != 0x0 && players[1] != 0x0) {
            playStatus = GameStatus.playing;
        }
    }

    //玩家落子
    function oneStep(uint8 _x, uint8 _y) public returns (address) {
        require(playStatus != GameStatus.over, "Game is over");
        require(playStatus != GameStatus.start, "Game is not start");
        require(msg.sender == players[playerTurn - 1], "Not your turn");
        require(checkBoundary(_x, _y), "Out of boundary");
        require(chessboard[_x][_y] == 0, "Can not move chess here");

        //放置棋子
        chessboard[_x][_y] = playerTurn;
        stone_num++;
        emit OneStep(_x, _y);

        // 检查是否五子连珠
        if (checkFive(_x, _y, 1, 0) || // 水平方向
        checkFive(_x, _y, 0, 1) || // 垂直方向
        checkFive(_x, _y, 1, 1) || // 左上到右下方向
        checkFive(_x, _y, 1, - 1)) {// 右上到左下方向
            winGame(playerTurn);
            // 五子连珠达成，当前用户胜利
            return;
        }

        if (stone_num == 225) {
            // 棋盘放满，和局
            playStatus = GameStatus.over;
            playerTurn = 0;
            emit GameOver(0);
        }
        else {
            // 修改下一步棋的落子方
            if (playerTurn == 1) {
                playerTurn = 2;
            }
            else {
                playerTurn = 1;
            }
            playStatus = GameStatus.playing;
        }
    }

    function getNewestState() public view returns (uint8[15][15], address, GameStatus) {
        return (chessboard, players[playerTurn], playStatus);
    }

    function getMyMoney() public {
        uint senderMoney = playersMoney[msg.sender];
        require(playStatus == GameStatus.over, "Game is not over");
        require(senderMoney > 0, "You have got your money");
        require(address(this).balance >= senderMoney, "I have no enough money");
        address(msg.sender).transfer(senderMoney);
    }


    //检查边界
    function checkBoundary(uint8 _x, uint8 _y) private pure returns (bool) {
        return (_x < boardSize && _y < boardSize);
    }

    //检查是否五子连珠
    function checkFive(uint8 _x, uint8 _y, int _xdir, int _ydir) private view returns (bool) {
        uint8 count = 0;
        count += countChess(_x, _y, _xdir, _ydir);
        // 检查反方向
        count += countChess(_x, _y, - 1 * _xdir, - 1 * _ydir) - 1;
        if (count >= 5) {
            return true;
        }
        return false;
    }

    //数棋子的数量
    function countChess(uint8 _x, uint8 _y, int _xdir, int _ydir) private view returns (uint8) {
        uint8 count = 1;
        while (count <= 5) {
            uint8 x = uint8(int8(_x) + _xdir * count);
            uint8 y = uint8(int8(_y) + _ydir * count);
            if (checkBoundary(x, y) && chessboard[x][y] == chessboard[_x][_y]) {
                count += 1;
            }
            else {
                return count;
            }
        }
    }

    //标记胜出者
    function winGame(uint8 _winner) private {
        require(0 <= _winner && _winner <= 2, "invalid winner state");
        winner = _winner;
        // 游戏结束
        if (winner != 0) {
            playStatus = GameStatus.over;
            playerTurn = 0;
            emit GameOver(winner);
        }
    }
}
