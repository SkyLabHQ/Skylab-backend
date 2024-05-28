// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBidTacToe} from "./MercuryBidTacToe.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract BidTacToe is Initializable {
    /*//////////////////////////////////////////////////////////////
                            Static Gameplay Data
    //////////////////////////////////////////////////////////////*/
    address public player1;
    address public player2;
    uint256 public gridWidth;
    uint256 public gridHeight;
    uint256 public lengthToWin;

    uint256 public gridMaxSelectionCount;
    uint256 public gridSelectionStrategy;
    address public mercuryBidTacToeAddress;
    address public privateLobbyAddress;

    /*//////////////////////////////////////////////////////////////
                            Dynamic gameplay data
    //////////////////////////////////////////////////////////////*/
    address[] private grid;
    uint256[] private gridSelectionCount;
    uint256 public currentSelectedGrid;
    uint256[] public allSelectedGrids;
    mapping(address => uint256) public gameStates;
    mapping(address => uint256) public timeouts;
    mapping(address => uint256) public balances;
    mapping(address => uint256) private commitedHashes;
    mapping(address => uint256[]) private revealedBids;
    mapping(address => uint256) public occupiedGridCounts;
    mapping(address => uint256) public playerMessage;
    mapping(address => uint256) public playerEmote;

    address public nextDrawWinner;

    // Static values
    uint256 universalTimeout;

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
    event BothCommittedBid(address player1, address player2);
    event BothRevealedBid(uint256 currentSelectedGrid, address[] grid, uint256 player1Balance, uint256 player2Balance, uint256 player1RevealedBids, uint256 player2RevealedBids, address winner);

    event WinGame(address indexed user, uint256 state);
    event LoseGame(address indexed user, uint256 state);

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "BidTacToe: msg.sender is not a valid player");
        _;
    }

    function initialize(
        MercuryBidTacToe.GameParams memory gameParams,
        address player,
        address _mercuryBidTacToeAddress,
        address _privateLobbyAddress
    ) public initializer {
        if (gameParams.universalTimeout == 0) {
            universalTimeout = 90;
        } else {
            universalTimeout = gameParams.universalTimeout;
        }
        player1 = player;
        gridWidth = gameParams.gridWidth;
        gridHeight = gameParams.gridHeight;
        lengthToWin = gameParams.lengthToWin;
        gridMaxSelectionCount = gameParams.gridMaxSelectionCount;
        gridSelectionStrategy = gameParams.gridSelectionStrategy;

        grid = new address[](gridWidth * gridHeight);
        gridSelectionCount = new uint256[](gridWidth * gridHeight);
        revealedBids[player1] = new uint256[](gridWidth * gridHeight);
        gameStates[player1] = 1;
        balances[player1] = gameParams.initialBalance;
        mercuryBidTacToeAddress = _mercuryBidTacToeAddress;
        privateLobbyAddress = _privateLobbyAddress;
    }

    function getGrid() external view returns (address[] memory) {
        return grid;
    }

    function getGridSelectionCount() external view returns (uint256[] memory) {
        return gridSelectionCount;
    }

    function getRevealedBids(address player) external view returns (uint256[] memory) {
        return revealedBids[player];
    }

    // Player 2 joins the game, do checks and generate the next grid
    function joinGame(address player) external {
        require(player2 == address(0), "BidTacToe: cannot join because player2 exists already");
        require(player1 != player, "BidTacToe: msg.sender is player1, but playing against yourself is not allowed");
        player2 = player;
        revealedBids[player2] = new uint256[](gridWidth * gridHeight);
        gameStates[player2] = 1;
        balances[player2] = balances[player1];

        initializeFutureGrids();
        generateNextGrid();
        setTimeoutForBothPlayers();
        if (uint256(keccak256(abi.encodePacked(block.timestamp, player1, player2))) % 2 == 0) {
            nextDrawWinner = player1;
        } else {
            nextDrawWinner = player2;
        }
        emit ReadyPlayerTwo(player1, player2);
    }

    // ethers.solidityPackedKeccak256(["uint256", "uint256"], [bid, salt]);
    function commitBid(uint256 hash) public virtual onlyPlayers {
        require(player2 != address(0), "BidTacToe: bid cannot start unless there are 2 players");
        require(gameStates[msg.sender] == 1, "BidTacToe: player gameState is not 1");
        require(timeouts[msg.sender] == 0 || block.timestamp <= timeouts[msg.sender], "BidTacToe: timeout has passed");

        commitedHashes[msg.sender] = hash;

        gameStates[msg.sender] = 2;
        timeouts[msg.sender] = 0;

        if (gameStates[getOtherPlayer()] == 2) {
            setTimeoutForBothPlayers();
            emit BothCommittedBid(player1, player2);
        }
        emit CommitBid(msg.sender, hash);
    }

    function revealBid(uint256 bid, uint256 salt) external onlyPlayers {
        require(gameStates[msg.sender] == 2, "BidTacToe: player gameState is not 2");
        require(gameStates[getOtherPlayer()] >= 2, "BidTacToe: opponent gameState is less than 2");
        require(
            commitedHashes[msg.sender] == uint256(keccak256(abi.encodePacked(bid, salt))),
            "BidTacToe: verification failed"
        );
        require(balances[msg.sender] >= bid, "BidTacToe: not enough balance");
        require(timeouts[msg.sender] == 0 || block.timestamp <= timeouts[msg.sender], "BidTacToe: timeout has passed");

        revealedBids[msg.sender][currentSelectedGrid] = bid;

        balances[msg.sender] -= bid;
        gameStates[msg.sender] = 3;
        timeouts[msg.sender] = 0;
        emit RevealBid(msg.sender, bid, salt);

        if (gameStates[getOtherPlayer()] == 3) {
            address bidWinner;
            address bidLoser;
            if (revealedBids[msg.sender][currentSelectedGrid] > revealedBids[getOtherPlayer()][currentSelectedGrid]) {
                bidWinner = msg.sender;
                bidLoser = getOtherPlayer();
            } else if (
                revealedBids[msg.sender][currentSelectedGrid] < revealedBids[getOtherPlayer()][currentSelectedGrid]
            ) {
                bidWinner = getOtherPlayer();
                bidLoser = msg.sender;
            } else {
                bidWinner = nextDrawWinner;
                bidLoser = getOtherPlayer(nextDrawWinner);
            }

            grid[currentSelectedGrid] = bidWinner;
            occupiedGridCounts[bidWinner] += 1;
            nextDrawWinner = bidLoser;

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
            address winner = bidWinner;
            if (gameStates[player1] == 1 && gameStates[player2] == 1) {
                winner = address(0);
            }
            emit BothRevealedBid(currentSelectedGrid, grid, balances[player1], balances[player2], revealedBids[player1][currentSelectedGrid], revealedBids[player2][currentSelectedGrid], winner);
        }
    }

    function claimTimeoutPenalty() external virtual onlyPlayers {
        require(timeouts[getOtherPlayer()] > 0, "BidTacToe: timeout isn't defined");
        require(block.timestamp > timeouts[getOtherPlayer()], "BidTacToe: timeout didn't pass yet");

        win(msg.sender, 6);
    }

    function surrender() external onlyPlayers {
        win(getOtherPlayer(), 8);
    }

    function setMessage(uint256 index) external onlyPlayers {
        playerMessage[msg.sender] = index;
    }

    function setEmote(uint256 index) external onlyPlayers {
        playerEmote[msg.sender] = index;
    }

    function initializeFutureGrids() internal {
        if (gridSelectionStrategy == 2) {
            // If strategy = 2, generate all selections (maxSelection * width * height) now
            for (uint256 i = 0; i < gridWidth * gridHeight * gridMaxSelectionCount; i++) {
                uint256 selection = generateSingleGridSelection(i);
                gridSelectionCount[selection] += 1;
                allSelectedGrids.push(selection);
            }

            gridSelectionCount = new uint256[](gridWidth * gridHeight);
        } else if (gridSelectionStrategy == 1) {
            // If strategy = 1, generate 1 future selection now
            allSelectedGrids.push(generateSingleGridSelection(1));
        }
    }

    function generateNextGrid() internal {
        // If future grids has one, use that, else generate
        uint256 nthSelection = occupiedGridCounts[player1] + occupiedGridCounts[player2];
        if (allSelectedGrids.length > nthSelection) {
            require(gridSelectionStrategy != 0, "BidTacToe DEBUG: reading future grids, strategy cannot be 0");
            currentSelectedGrid = allSelectedGrids[nthSelection];
        } else {
            require(gridSelectionStrategy == 0, "BidTacToe DEBUG: generating fresh grid, strategy must be 0");
            currentSelectedGrid = generateSingleGridSelection(1);
            allSelectedGrids.push(currentSelectedGrid);
        }
        gridSelectionCount[currentSelectedGrid] += 1;

        // If strateegy = 1, generate 1 future selection now
        if (gridSelectionStrategy == 1) {
            allSelectedGrids.push(generateSingleGridSelection(1));
        }
    }

    function generateSingleGridSelection(uint256 nonce) internal view returns (uint256) {
        uint256 tempHash = uint256(
            keccak256(abi.encodePacked(player1, player2, balances[player1], balances[player2], block.timestamp, nonce))
        );
        uint256 tempSelection = tempHash % (gridWidth * gridHeight);

        uint256 antiCollision = tempSelection;
        while (gridSelectionCount[antiCollision] >= gridMaxSelectionCount) {
            antiCollision += 1;
            if (antiCollision >= grid.length) {
                antiCollision = 0;
            }
        }

        return antiCollision;
    }

    function setTimeoutForBothPlayers() internal {
        timeouts[player1] = block.timestamp + universalTimeout;
        timeouts[player2] = block.timestamp + universalTimeout;
    }

    function getOtherPlayer() private view returns (address) {
        return msg.sender == player2 ? player1 : player2;
    }

    function getOtherPlayer(address player) internal view returns (address) {
        return player == player2 ? player1 : player2;
    }

    function existsOverallWinner() private view returns (bool) {
        return inARowHelper(0, -1) + inARowHelper(0, 1) - 1 >= lengthToWin
            || inARowHelper(-1, 0) + inARowHelper(1, 0) - 1 >= lengthToWin
            || inARowHelper(-1, -1) + inARowHelper(1, 1) - 1 >= lengthToWin
            || inARowHelper(1, -1) + inARowHelper(-1, 1) - 1 >= lengthToWin;
    }

    function inARowHelper(int256 stepX, int256 stepY) private view returns (uint256) {
        int256 currentX = int256(currentSelectedGrid) % int256(gridWidth);
        int256 currentY = int256(currentSelectedGrid) / int256(gridWidth);
        uint256 currentLength = 0;

        while (currentX >= 0 && currentX < int256(gridWidth) && currentY >= 0 && currentY < int256(gridHeight)) {
            if (grid[uint256(currentY) * gridWidth + uint256(currentX)] == grid[currentSelectedGrid]) {
                currentLength += 1;
            }
            currentX += stepX;
            currentY += stepY;
        }
        return currentLength;
    }

    function win(address player, uint256 state) internal virtual {
        gameStates[player] = state;
        emit WinGame(player, state);
        address otherPlayer = getOtherPlayer(player);
        gameStates[otherPlayer] = state + 1;
        emit LoseGame(otherPlayer, state + 1);
        (bool bttSuceed,) =
            mercuryBidTacToeAddress.call(abi.encodeWithSignature("handleWinLoss(address,address)", player, otherPlayer));
        require(bttSuceed, "BidTacToe: handleWinLoss failed");
        if (privateLobbyAddress != address(0)) {
            (bool lobbySuceed,) =
                privateLobbyAddress.call(abi.encodeWithSignature("handleWinLoss(address,address)", player, otherPlayer));
            require(lobbySuceed, "BidTacToe: handleWinLoss failed");
        }
    }
}
