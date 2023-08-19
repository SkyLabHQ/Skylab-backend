// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SkylabBidTacToe } from "./SkylabBidTacToe.sol";

contract BidTacToe {
    // ====================
    // Static gameplay data
    // ====================
    address public player1;
    address public player2;
    uint256 public gridWidth;
    uint256 public gridHeight;
    uint256 public lengthToWin;
    SkylabBidTacToe public skylabBidTacToe;

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
    address public nextDrawWinner;

    // Static values
    uint constant universalTimeout = 300;

    /*
    *   State 1: next grid has been selected, both players are ready to bid for it
    *   State 2: both players have committed their bids
    *   State 3: both players have revealed their bids, winner of the grid is determined; if there's an overall winner, end the game; otherwise, go back to state 1
    *   State 4: win by connecting
    *   State 5: lose by connecting
    *   State 6: win by timeout
    *   State 7: lose by timeout
    *   State 8: win by surrender
    *   State 9: lose by surrender
    *   State 10: win by grid count
    *   State 11: lose by grid count
    */ 


    event ReadyPlayerTwo(address indexed player1, address indexed player2);
    event CommitBid(address indexed player, uint256 hash);
    event RevealBid(address indexed player, uint256 amount, uint256 salt);
    event WinGrid(address indexed player, uint256 grid);
    event DrawGrid();

    event WinGame(address indexed user, uint256 state);
    event LoseGame(address indexed user, uint256 state);

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "BidTacToe: msg.sender is not a valid player");
        _;
    }

    constructor(SkylabBidTacToe.GameParams memory gameParams, address player, address callback) {
        player1 = player;
        gridWidth = gameParams.gridWidth;
        gridHeight = gameParams.gridHeight;
        lengthToWin = gameParams.lengthToWin;

        grid = new address[](gridWidth * gridHeight);
        gameStates[player1] = 1;
        balances[player1] = gameParams.initialBalance;
        skylabBidTacToe = SkylabBidTacToe(callback);
    }

    // Player 2 joins the game, do checks and generate the next grid
    function joinGame(address player) external {
        require(player2 == address(0), "BidTacToe: cannot join because player2 exists already");
        require(player1 != player, "BidTacToe: msg.sender is player1, but playing against yourself is not allowed");
        player2 = player;
        gameStates[player2] = 1;
        balances[player2] = balances[player1];

        generateNextGrid();
        setTimeoutForBothPlayers();
        if (uint(keccak256(abi.encodePacked(block.timestamp, player1, player2))) % 2 == 0) {
            nextDrawWinner = player1;
        } else {
            nextDrawWinner = player2;
        }
        emit ReadyPlayerTwo(player1, player2);
    }

    // https://ethereum.stackexchange.com/questions/82595/how-to-keccak-256-hash-in-front-end-javascript-before-passing-it-to-my-smart-con
    function commitBid(uint256 hash) external onlyPlayers {
        require(player2 != address(0), "BidTacToe: bid cannot start unless there are 2 players");
        require(gameStates[msg.sender] == 1, "BidTacToe: player gameState is not 1");

        commitedHashes[msg.sender] = hash;

        gameStates[msg.sender] = 2;
        timeouts[msg.sender] = 0;

        if (gameStates[getOtherPlayer()] == 2) {
            setTimeoutForBothPlayers();
        }
        emit CommitBid(msg.sender, hash);
    }

    function revealBid(uint256 bid, uint256 salt) external onlyPlayers {
        require(gameStates[msg.sender] == 2, "BidTacToe: player gameState is not 2");
        require(gameStates[getOtherPlayer()] >= 2, "BidTacToe: opponent gameState is less than 2");
        require(commitedHashes[msg.sender] == uint(keccak256(abi.encodePacked(bid, salt))), "BidTacToe: verification failed");
        require(balances[msg.sender] >= bid, "BidTacToe: not enough balance");

        revealedBids[msg.sender] = bid;

        balances[msg.sender] -= bid;
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
                bidWinner = nextDrawWinner;
                bidLoser = getOtherPlayer(nextDrawWinner);
            }

            grid[currentSelectedGrid] = bidWinner;
            occupiedGridCounts[bidWinner] += 1;
            nextDrawWinner = bidLoser;
            emit WinGrid(bidWinner, currentSelectedGrid);

            if (existsOverallWinner()) {
                win(bidWinner, 4);
            } else if (occupiedGridCounts[bidWinner] * 2 > gridWidth * gridHeight) {
                win(bidWinner, 10);
            } else {
                generateNextGrid();
                gameStates[player1] = 1;
                gameStates[player2] = 1;
                setTimeoutForBothPlayers();
            }
        }
    }

    function claimTimeoutPenalty() external onlyPlayers {
        require(timeouts[getOtherPlayer()] > 0, "BidTacToe: timeout isn't defined");
        require(block.timestamp > timeouts[getOtherPlayer()], "BidTacToe: timeout didn't pass yet");

        win(msg.sender, 6);
    }

    function surrender() external onlyPlayers {
        win(getOtherPlayer(), 8);
    }
    

    function generateNextGrid() internal {
        uint256 tempHash = uint(keccak256(abi.encodePacked(player1, player2, balances[player1], balances[player2], block.timestamp)));
        uint256 tempSelection = tempHash % (gridWidth * gridHeight);

        uint256 antiCollision = tempSelection;
        while (grid[antiCollision] != address(0)) {
            antiCollision += 1;
            if (antiCollision >= grid.length) {
                antiCollision = 0;
            }
            if (antiCollision == tempSelection) {
                // shouldn't happen
                require(false, "BidTacToe: grid selection looped around and that's not possible");
            }
        }

        currentSelectedGrid = antiCollision;
    }

    function setTimeoutForBothPlayers() internal {
        timeouts[player1] = block.timestamp + universalTimeout;
        timeouts[player2] = block.timestamp + universalTimeout;
    }

    function getOtherPlayer() private view returns (address) {
        return msg.sender == player2 ? player1 : player2;
    }

    function getOtherPlayer(address player) private view returns (address) {
        return player == player2 ? player1 : player2;
    }

    function existsOverallWinner() private view returns (bool) {
        return inARowHelper(0, -1) + inARowHelper(0, 1) - 1 >= lengthToWin || inARowHelper(-1, 0) + inARowHelper(1, 0) - 1 >= lengthToWin || inARowHelper(-1, -1) + inARowHelper(1, 1) - 1 >= lengthToWin || inARowHelper(1, -1) + inARowHelper(-1, 1) - 1 >= lengthToWin;
    }

    function inARowHelper(int stepX, int stepY) private view returns (uint256) {
        int currentX = int(currentSelectedGrid) % int(gridWidth);
        int currentY = int(currentSelectedGrid) / int(gridWidth);
        uint currentLength = 0;
        
        while (currentX >= 0 && currentX < int(gridWidth) && currentY >= 0 && currentY < int(gridHeight)) {
            if (grid[uint(currentY) * gridWidth + uint(currentX)] == grid[currentSelectedGrid]) {
                currentLength += 1;
            }
            currentX += stepX;
            currentY += stepY;
        }
        return currentLength;
    }

    function win(address player, uint256 state) private {
        gameStates[player] = state;
        emit WinGame(player, state);
        address otherPlayer = getOtherPlayer(player);
        gameStates[otherPlayer] = state + 1;
        emit LoseGame(otherPlayer, state + 1);

        skylabBidTacToe.handleWin(player);
        skylabBidTacToe.handleLoss(otherPlayer);
    }
}
