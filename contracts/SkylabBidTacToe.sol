// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BidTacToe {
    // ====================
    // Static gameplay data
    // ====================
    address public player1;
    address public player2;
    uint256 public gridWidth;
    uint256 public gridHeight;
    uint256 public lengthToWin;

    // ====================
    // Dynamic gameplay data
    // ====================
    address[] public grid;
    uint256 public currentSelectedGrid;
    mapping(address => uint256) public gameStates;
    mapping(address => uint256) public timeouts;
    mapping(address => uint256) public balances;
    mapping(address => uint256) private commitedHashes;
    mapping(address => uint256) public revealedBids;
    mapping(address => uint256) public occupiedGridCounts;

    // Static values
    uint constant universalTimeout = 300;

    /*
    *   State 1: next grid has been selected, both players are ready to bid for it
    *   State 2: both players have committed their bids
    *   State 3: both players have revealed their bids, winner of the grid is determined; if there's an overall winner, end the game; otherwise, go back to state 1
    *   State 4-6: result state
    */ 


    event ReadyPlayerTwo(address indexed player1, address indexed player2);
    event CommitBid(address indexed player, uint256 hash);
    event RevealBid(address indexed player, uint256 amount, uint256 salt);
    event WinGrid(address indexed player, uint256 grid);
    event DrawGrid();
    event WinGame(address indexed user);
    event LoseGame(address indexed user);
    event TimeoutWinGame(address indexed user);
    event TimeoutLoseGame(address indexed user);
    event GridCountWinGame(address indexed user);
    event GridCountLoseGame(address indexed user);

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "SkylabBidTacToe: msg.sender is not a valid player");
        _;
    }

    constructor(uint gridWidth, uint gridHeight, uint lengthToWin, uint initialBalance) {
        player1 = msg.sender;
        gridWidth = gridWidth;
        gridHeight = gridHeight;
        lengthToWin = lengthToWin;

        grid = new address[](gridWidth * gridHeight);
        gameStates[player1] = 1;
        balances[player1] = initialBalance;
    }

    // Player 2 joins the game, do checks and generate the next grid
    function joinGame() external {
        require(player2 == address(0), "SkylabBidTacToe: cannot join because player2 exists already");
        require(msg.sender != player1, "SkylabBidTacToe: msg.sender is player1, but playing against yourself is not allowed");
        player2 = msg.sender;
        gameStates[player2] = 1;
        balances[player2] = initialBalance;

        generateNextGrid();
        setTimeoutForBothPlayers();
        emit ReadyPlayerTwo(player1, player2);
    }

    // https://ethereum.stackexchange.com/questions/82595/how-to-keccak-256-hash-in-front-end-javascript-before-passing-it-to-my-smart-con
    function commitBid(uint256 hash) external onlyPlayers {
        require(gameStates[msg.sender] == 1, "SkylabBidTacToe: player gameState is not 1");
        require(gameStates[getOtherPlayer()] == 1, "SkylabBidTacToe: opponent gameState is not 1");

        commitedHashes[msg.sender] = hash;

        gameStates[msg.sender] = 2;
        timeouts[msg.sender] = 0;

        if (gameStates[getOtherPlayer()] == 2) {
            setTimeoutForBothPlayers();
        }
        emit CommitBid(msg.sender, hash);
    }

    function revealBid(uint256 bid, uint256 salt) external onlyPlayers {
        require(gameStates[msg.sender] == 2, "SkylabBidTacToe: player gameState is not 2");
        require(gameStates[getOtherPlayer()] == 2, "SkylabBidTacToe: opponent gameState is not 2");
        require(commitedHashes[msg.sender] == uint(keccak256(abi.encodePacked(bid, salt))), "SkylabBidTacToe: verification failed");
        require(balances[msg.sender] >= bid, "SkylabBidTacToe: not enough balance");

        revealedBids[msg.sender] = bid;

        gameStates[msg.sender] = 3;
        timeouts[msg.sender] = 0;
        emit RevealBid(msg.sender, bid, salt);

        if (gameStates[getOtherPlayer()] == 3) {
            address bidWinner;
            address bidLoser;
            if (revealedBids[msg.sender] > revealedBids[getOtherPlayer()]) {
                bidWinner = msg.sender;
                bidLoser = getOtherPlayer();
            } else if (revealedBids[msg.sender] < revealedBids[getOtherPlayer()]) {
                bidWinner = getOtherPlayer();
                bidLoser = msg.sender;
            } else {
                gameStates[player1] = 1;
                gameStates[player2] = 1;
                setTimeoutForBothPlayers();
                emit DrawGrid();
                return;
            }

            balances[bidWinner] -= revealedBids[bidWinner];
            grid[currentSelectedGrid] = bidWinner;
            occupiedGridCounts[bidWinner] += 1;
            emit WinGrid(bidWinner, currentSelectedGrid);

            if (existsOverallWinner()) {
                win(bidWinner);
                lose(bidLoser);
            } else if (occupiedGridCounts[bidWinner] + occupiedGridCounts[bidLoser] >= gridWidth * gridHeight) {
                if (occupiedGridCounts[bidWinner] < occupiedGridCounts[bidLoser]) {
                    gridCountWin(bidLoser);
                    gridCountLose(bidWinner);
                } else {
                    gridCountWin(bidWinner);
                    gridCountLose(bidLoser);
                }
            } else {
                generateNextGrid();
                gameStates[player1] = 1;
                gameStates[player2] = 1;
                setTimeoutForBothPlayers();
            }
        }
    }

    function claimTimeoutPenalty() external onlyPlayers {
        require(timeouts[getOtherPlayer()] > 0, "SkylabBidTacToe: timeout isn't defined");
        require(block.timestamp > timeouts[getOtherPlayer()], "SkylabBidTacToe: timeout didn't pass yet");

        timeoutWin(msg.sender);
        timeoutLose(getOtherPlayer());
    }
    

    function generateNextGrid() internal {
        uint256 tempSelection = uint(keccak256(abi.encodePacked(player1, player2, balances[player1], balances[player2]))) % (gridWidth * gridHeight);

        uint256 antiCollision = tempSelection;
        while (grid[antiCollision] != address(0)) {
            antiCollision += 1;
            if (antiCollision >= grid.length) {
                antiCollision = 0;
            }
            if (antiCollision == tempSelection) {
                // shouldn't happen
                require(false, "SkylabBidTacToe: grid selection looped around and that's not possible");
            }
        }

        currentSelectedGrid = antiCollision;
    }

    function setTimeoutForBothPlayers() internal {
        timeout[player1] = block.timestamp + universalTimeout;
        timeout[player2] = block.timestamp + universalTimeout;
    }

    function getOtherPlayer() private pure returns (address) {
        return msg.sender == player2 ? player1 : player2;
    }

    function existsOverallWinner() private pure returns (bool) {
        return inARowHelper(0, -1) + inARowHelper(0, 1) - 1 >= lengthToWin || inARowHelper(-1, 0) + inARowHelper(1, 0) - 1 >= lengthToWin || inARowHelper(-1, -1) + inARowHelper(1, 1) - 1 >= lengthToWin || inARowHelper(1, -1) + inARowHelper(-1, 1) - 1 >= lengthToWin
        
    }

    function inARowHelper(int stepX, int stepY) private pure returns (uint256) {
        int currentX = int(currentSelectedGrid) % int(gridWidth);
        int currentY = int(currentSelectedGrid) / int(gridWidth);
        int currentLength = 0;
        
        while (currentX >= 0 && currentX < gridWidth && currentY >= 0 && currentY < gridHeight) {
            if (grid[uint(currentX) * gridWidth + uint(currentY)] == grid[currentSelectedGrid]) {
                currentLength += 1;
            }
            currentX += stepX;
            currentY += stepY;
        }
        return currentLength;
    }

    function win(address player) private {
        // report back the results
        gameStates[player] = 4;
        emit WinGame(player);
    }

    function lose(address player) private {
        // report back the results
        gameStates[player] = 5;
        emit LoseGame(player);
    }

    function timeoutWin(address player) private {
        // report back the results
        gameStates[player] = 6;
        emit TimeoutWinGame(player);
    }

    function timeoutLose(address player) private {
        // report back the results
        gameStates[player] = 7;
        emit TimeoutLoseGame(player);
    }

    function gridCountWin(address player) private {
        // report back the results
        gameStates[player] = 8;
        emit GridCountWinGame(player);
    }

    function gridCountLose(address player) private {
        // report back the results
        gameStates[player] = 9;
        emit GridCountLoseGame(player);
    }
}


contract SkylabGameFlightRace is SkylabGameBase {

    mapping(address => address) public gamePerPlayer;
    address[] public gameQueue;



    constructor(address skylabBaseAddress) SkylabGameBase(skylabBaseAddress) {

    }


}