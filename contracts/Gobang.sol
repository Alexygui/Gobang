pragma solidity ^0.4.17;


contract Gobang {
    address owner;

    struct Player {
    address id;
    int8 lastX;
    int8 lastY;
    }

    Player playerBlack;

    Player playerWhite;

    uint128 BET_MONEY = 1 ether;

    bool isBlackPlay = true;

    bool isPlaying = false;

    uint8[15][15] chessboard;

    address winner;

    mapping (address => uint128) playersMoney;
    // 三维数组记录横向，纵向，左斜，右斜的移动
    int8[2][2][4] dir = [
    [[int8(- 1), int8(0)], [int8(1), int8(0)]], // 横向
    [[int8(0), int8(- 1)], [int8(0), int8(1)]], // 竖着
    [[int8(- 1), int8(- 1)], [int8(1), int8(1)]], // 左斜
    [[int8(1), int8(- 1)], [int8(- 1), int8(1)]]            // 右斜
    ];


    function Gobang() public {
        //    constructor() public {
        initGame();
        owner = msg.sender;
    }

    function joinGame() public payable {
        require(playerBlack.id == 0x0 || playerWhite.id == 0x0);
        require(msg.value >= BET_MONEY);
        if (playerBlack.id == 0x0) {
            playerBlack.id = msg.sender;
        }
        else {
            playerWhite.id = msg.sender;
        }
        if (playerBlack.id != 0x0 && playerWhite.id != 0x0) {
            isPlaying = true;
        }
    }

    function oneStep(int8 x, int8 y) public returns (address) {
        bool isBlackStep = isBlackPlay && playerBlack.id == msg.sender;
        bool isWhiteStep = !isBlackPlay && playerWhite.id == msg.sender;
        require(chessboard[uint(x)][uint(y)] == 0 && (isBlackStep || isWhiteStep));

        if (isBlackStep) {
            chessboard[uint(x)][uint(y)] = 1;
            playerBlack.lastX = x;
            playerBlack.lastY = y;
        }
        else if (isWhiteStep) {
            chessboard[uint(x)][uint(y)] = 2;
            playerWhite.lastX = x;
            playerWhite.lastY = y;
        }

        bool isWin = checkWinner(x, y);
        if (isWin) {
            if (isBlackPlay) {
                winner = playerBlack.id;
                playersMoney[playerWhite.id] -= BET_MONEY;
                playersMoney[winner] += BET_MONEY;
            }
            else {
                winner = playerWhite.id;
                playersMoney[playerBlack.id] -= BET_MONEY;
                playersMoney[winner] += BET_MONEY;
            }
            initGame();
            return winner;
        }
        isBlackPlay = !isBlackPlay;
        return 0x0;
    }

    function checkWinner(int8 x, int8 y) internal view returns (bool) {
        uint8 max = 0;
        int8 tempX = x;
        int8 tempY = y;
        for (uint i = 0; i < 4; i++) {
            uint8 count = 1;
            //j为0,1分别为棋子的两边方向，比如对于横向的时候，j=0,表示下棋位子的左边，j=1的时候表示右边
            for (uint j = 0; j < 2; j++) {
                bool flag = true;
                // while语句中为一直向某一个方向遍历
                // 有相同颜色的棋子的时候，Count++
                // 否则置flag为false，结束该该方向的遍历
                while (flag) {
                    tempX = tempX + dir[i][j][0];
                    tempY = tempY + dir[i][j][1];
                    if (chessboard[uint(tempX)][uint(tempY)] == chessboard[uint(x)][uint(y)]
                    && tempX >= 0 && tempX < 15 && tempY >= 0 && tempY < 15) {
                        count++;
                    }
                    else {
                        flag = false;
                    }
                }
                tempX = x;
                tempY = y;
            }
            if (count >= 5) {
                max = 1;
                break;
            }
            else {
                max = 0;
            }
        }
        return max == 1;
    }

    function getNewestState() public view returns (bool, bool, int8, int8, int8, int8) {
        return (isPlaying, isBlackPlay, playerBlack.lastX, playerBlack.lastY, playerWhite.lastX, playerWhite.lastY);
    }

    function getMyMoney() public {
        uint senderMoney = playersMoney[msg.sender];
        require(senderMoney > 0 && address(this).balance >= senderMoney && playerBlack.id == 0x0);
        address(msg.sender).transfer(senderMoney);
    }

    function initGame() private {
        playerBlack = Player(0x0, - 1, - 1);
        playerWhite = Player(0x0, - 1, - 1);
        isBlackPlay = true;
        isPlaying = false;
        winner = 0x0;
    }
}
