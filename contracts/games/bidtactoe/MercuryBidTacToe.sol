// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";
import {LibBidTacToe} from "./lib/LibBidTacToe.sol";

contract MercuryBidTacToe is MercuryGameBase {
    struct GameParams {
        uint64 gridWidth;
        uint64 gridHeight;
        uint64 lengthToWin;
        uint64 initialBalance;
    }

    struct PlaneMetadata {
        uint64 token1Level;
        uint64 token1Points;
        uint64 token2Level;
        uint64 token2Points;
    }

    function initialize(address _protocol) public override {
        super.initialize(_protocol);
    }

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) public gamePerPlayer;
    mapping(address => GameParams) public paramsPerGame;
    mapping(address => PlaneMetadata) public planeMetadataPerGame;
    // collecton to default game queue
    mapping(address => address) public defaultGameQueue;

    mapping(address => bool) public validBidTacToeBots;

    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    function createLobby(
        uint64 gridWidth,
        uint64 gridHeight,
        uint64 lengthToWin,
        uint64 initialBalance
    ) external {
        createGame(GameParams(gridWidth, gridHeight, lengthToWin, initialBalance));
    }

    function joinLobby(address lobby) external {
        joinGame(lobby, msg.sender);
    }

    function createOrJoinDefault() external {
        address aviation = burnerAddressToAviation(msg.sender);
        if (defaultGameQueue[aviation] == address(0)) {
            defaultGameQueue[aviation] = msg.sender;
        } else {
            address gameAddress = createGame(LibBidTacToe.defaultParams());
            address player2 = defaultGameQueue[aviation];
            delete defaultGameQueue[aviation];
            joinGame(gameAddress, player2);
        }
    }

    function createBotGame(address bot) external {
        require(validBidTacToeBots[bot], "MercuryBidTacToe: bot is a valid bot");
        address gameAddress = createGame(LibBidTacToe.defaultParams());
        joinGame(gameAddress, bot);
    }

    function createGame(GameParams memory gameParams) internal returns (address) {
        require(!playerCreatedGameOrQueued(msg.sender), "MercuryBidTacToe: player already created or queued for a game");
        
        address newGame = LibBidTacToe.createGame(gameParams, msg.sender, address(this));
        address aviation = burnerAddressToAviation(msg.sender);
        paramsPerGame[newGame] = gameParams;
        planeMetadataPerGame[newGame] =
            PlaneMetadata(getAviationLevel(msg.sender, aviation), getAviationPoints(msg.sender, aviation), 0, 0);
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        super.baseCreateLobby(newGame, aviation);
        return newGame;
    }

    function joinGame(address gameAddress, address player2) internal {
        require(gameExists[gameAddress], "MercuryBidTacToe: lobby does not exist");
        require(!playerCreatedGameOrQueued(player2), "MercuryBidTacToe: player already created or queued for a game");
        require(isIdenticalAviation(LibBidTacToe.getPlayer1(gameAddress), player2), "MercuryBidTacToe: aviation does not match");

        LibBidTacToe.joinGame(gameAddress, player2);
        address aviation = burnerAddressToAviation(msg.sender);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2, aviation);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2, aviation);
        super.baseJoinLobby(gameAddress, aviation);
    }

    function deleteLobby(address lobby) external {
        require(gameExists[lobby], "MercuryBidTacToe: lobby does not exist");
        require(planeMetadataPerGame[lobby].token2Level == 0 && planeMetadataPerGame[lobby].token2Points == 0, "MercuryBidTacToe: the game is ongoing");

        address aviation = burnerAddressToAviation(msg.sender);
        super.baseJoinLobby(lobby, aviation);
        super.baseQuitLobby(lobby, aviation);
        delete gameExists[lobby];
        delete paramsPerGame[lobby];
        delete planeMetadataPerGame[lobby];
        delete gamePerPlayer[msg.sender];
    }

    function withdrawFromQueue() external {
        address aviation = burnerAddressToAviation(msg.sender);
        require(msg.sender == defaultGameQueue[aviation], "MercuryBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue[aviation];
    }

    function playerCreatedGameOrQueued(address player) internal view returns (bool) {
        address aviation = burnerAddressToAviation(player);
        return gamePerPlayer[player] != address(0) || defaultGameQueue[aviation] == player;
    }

    function handleWinLoss(address winnerBurner, address loserBurner) external {
        require(gameExists[msg.sender], "MercuryBidTacToe: msg.sender is not a game");
        require(
            gamePerPlayer[winnerBurner] == msg.sender && gamePerPlayer[loserBurner] == msg.sender,
            "MercuryBidTacToe: burner addresses does not belong to this game"
        );
        MercuryBase aviation = MercuryBase(burnerAddressToAviation(winnerBurner));
        uint256 winnerTokenId = cleanUp(winnerBurner, aviation);
        uint256 loserTokenId = cleanUp(loserBurner, aviation);
        super.baseQuitLobby(msg.sender, address(aviation));
        emit WinGame(winnerTokenId, aviation.ownerOf(winnerTokenId));
        emit LoseGame(loserTokenId, aviation.ownerOf(loserTokenId));
        aviation.aviationMovePoints(winnerTokenId, loserTokenId);
        delete gameExists[msg.sender];
    }

    function cleanUp(address burner, MercuryBase aviation) private returns (uint256) {
        uint256 tokenId = burnerAddressToTokenId(burner);
        aviation.aviationUnlock(tokenId);
        delete gamePerPlayer[burner];
        return tokenId;
    }

    function getAviationLevel(address burner, address aviation) internal view returns (uint64) {
        return uint64(MercuryBase(aviation).aviationLevels(burnerAddressToTokenId(burner)));
    }

    function getAviationPoints(address burner, address aviation) internal view returns (uint64) {
        return uint64(MercuryBase(aviation).aviationPoints(burnerAddressToTokenId(burner)));
    }

    function registerBot(address bot, bool register) external onlyOwner {
        validBidTacToeBots[bot] = register;
    }
}
