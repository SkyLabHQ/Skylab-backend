// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";
import {MercuryBTTPrivateLobbyFactory} from "./MercuryBTTPrivateLobbyFactory.sol";
import {LibBidTacToe} from "./lib/LibBidTacToe.sol";

contract MercuryBidTacToe is MercuryGameBase, MercuryBTTPrivateLobbyFactory {
    struct GameParams {
        uint64 gridWidth;
        uint64 gridHeight;
        uint64 lengthToWin;
        uint64 initialBalance;
        bool isBot;
    }

    struct PlaneMetadata {
        uint64 token1Level;
        uint64 token1Points;
        uint64 token2Level;
        uint64 token2Points;
    }

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) public gamePerPlayer;
    mapping(address => address) playerToOpponent;
    mapping(address => uint256) playerToTimeout;
    mapping(address => GameParams) public paramsPerGame;
    mapping(address => PlaneMetadata) public planeMetadataPerGame;
    // collecton to default game queue
    mapping(address => address) public defaultGameQueue;
    mapping(address => bool) public validBidTacToeBots;

    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    function initialize(address _protocol) public override {
        super.initialize(_protocol);
    }

    function createOrJoinDefault() external {
        require(!playerCreatedGameOrQueued(msg.sender), "MercuryBidTacToe: player already created or queued for a game");
        address aviation = burnerAddressToAviation(msg.sender);
        if (defaultGameQueue[aviation] == address(0)) {
            defaultGameQueue[aviation] = msg.sender;
        } else {
            address defaultPlayer = defaultGameQueue[aviation];
            if (burnerAddressToAviation(defaultPlayer) != aviation) {
                defaultGameQueue[aviation] = msg.sender;
            } else {
                playerToOpponent[defaultPlayer] = msg.sender;
                playerToOpponent[msg.sender] = defaultPlayer;
                playerToTimeout[defaultPlayer] = block.timestamp + 30 seconds;
                playerToTimeout[msg.sender] = block.timestamp + 30 seconds;
                delete defaultGameQueue[aviation];
            }
        }
    }

    function setActiveQueue() public {
        require(block.timestamp <= playerToTimeout[msg.sender], "MercuryBidTacToe: timeout reached");
        address opponent = playerToOpponent[msg.sender];
        require(playerToOpponent[msg.sender] == opponent && playerToOpponent[opponent] == msg.sender, "MercuryBidTacToe: opponent not match");
        if(playerToTimeout[opponent] != 0) {
            playerToTimeout[msg.sender] = 0;
        } else {
            address gameAddress = createGame(LibBidTacToe.defaultParams());
            joinGame(gameAddress, opponent);
            delete playerToOpponent[msg.sender];
            delete playerToOpponent[opponent];
            delete playerToTimeout[msg.sender];
        }
    }

    function activeQueueTimeout() public {
        address opponent = playerToOpponent[msg.sender];
        require(block.timestamp > playerToTimeout[opponent], "MercuryBidTacToe: timeout not reached");
        require(playerToOpponent[msg.sender] == opponent && playerToOpponent[opponent] == msg.sender, "MercuryBidTacToe: opponent not match");
        address activePlayer;
        if(playerToTimeout[msg.sender] == 0) activePlayer = msg.sender;
        if(activePlayer != address(0)) {
            address aviation = burnerAddressToAviation(activePlayer);
            defaultGameQueue[aviation] = activePlayer;
        }
        delete playerToOpponent[msg.sender];
        delete playerToOpponent[opponent];
        delete playerToTimeout[msg.sender];
        delete playerToTimeout[opponent];
    }

    function createBotGame(address bot) external {
        require(validBidTacToeBots[bot], "MercuryBidTacToe: bot is a valid bot");
        address gameAddress = createGame(LibBidTacToe.defaultBotParams());
        LibBidTacToe.joinGame(gameAddress, bot);
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
        return newGame;
    }

    function joinGame(address gameAddress, address player2) internal {
        require(gameExists[gameAddress], "MercuryBidTacToe: game does not exist");
        require(!playerCreatedGameOrQueued(player2), "MercuryBidTacToe: player already created or queued for a game");
        require(
            isIdenticalAviation(LibBidTacToe.getPlayer1(gameAddress), player2),
            "MercuryBidTacToe: aviation does not match"
        );

        LibBidTacToe.joinGame(gameAddress, player2);
        address aviation = burnerAddressToAviation(msg.sender);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2, aviation);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2, aviation);
    }

    function createGameInPrivateLobby(GameParams memory gameParams) external returns (address) {
        require(lobbyExists[msg.sender], "MercuryBidTacToe: sender is a private lobby");
        return createGame(gameParams);
    }

    function joinGameInPrivateLobby(address gameAddress, address player2) external {
        require(lobbyExists[msg.sender], "MercuryBidTacToe: sender is a private lobby");
        joinGame(gameAddress, player2);
    }

    function deleteGameInPrivateLobby(address room) external {
        require(lobbyExists[msg.sender], "MercuryBidTacToe: sender is a private lobby");
        require(gameExists[room], "MercuryBTTPrivateLobby: lobby does not exist");
        require(
            planeMetadataPerGame[room].token2Level == 0 && planeMetadataPerGame[room].token2Points == 0,
            "MercuryBTTPrivateLobby: the game is ongoing"
        );

        delete gameExists[room];
        delete paramsPerGame[room];
        delete planeMetadataPerGame[room];
        delete gamePerPlayer[LibBidTacToe.getPlayer1(room)];
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
        if (burnerAddressToAviation(winnerBurner) != address(0)) {
            MercuryBase aviation = MercuryBase(burnerAddressToAviation(winnerBurner));
            uint256 winnerTokenId = cleanUp(winnerBurner, aviation);
            uint256 loserTokenId = cleanUp(loserBurner, aviation);
            emit WinGame(winnerTokenId, aviation.ownerOf(winnerTokenId));
            emit LoseGame(loserTokenId, aviation.ownerOf(loserTokenId));
            aviation.aviationMovePoints(winnerTokenId, loserTokenId);
        }
        delete gameExists[msg.sender];
    }

    function handleBotWinLoss(address playerBurner, bool playerWon) external {
        require(gameExists[msg.sender], "MercuryBidTacToe: msg.sender is not a game");
        require(
            gamePerPlayer[playerBurner] == msg.sender, "MercuryBidTacToe: burner address does not belong to this game"
        );
        if (burnerAddressToAviation(playerBurner) != address(0)) {
            MercuryBase aviation = MercuryBase(burnerAddressToAviation(playerBurner));
            uint256 playerTokenId = cleanUp(playerBurner, aviation);
            if (playerWon) {
                emit WinGame(playerTokenId, aviation.ownerOf(playerTokenId));
                aviation.aviationMovePoints(playerTokenId, 0);
            } else {
                emit LoseGame(playerTokenId, aviation.ownerOf(playerTokenId));
                aviation.aviationMovePoints(0, playerTokenId);
            }
        }
        delete gameExists[msg.sender];
    }

    function cleanUp(address burner, MercuryBase aviation) private returns (uint256) {
        uint256 tokenId = burnerAddressToTokenId(burner);
        unapproveForGame(tokenId, aviation);
        delete gamePerPlayer[burner];
        return tokenId;
    }

    function getAviationLevel(address burner, address aviation) public view returns (uint64) {
        if (aviation == address(0)) {
            return 0;
        }
        return uint64(MercuryBase(aviation).aviationLevels(burnerAddressToTokenId(burner)));
    }

    function getAviationPoints(address burner, address aviation) public view returns (uint64) {
        if (aviation == address(0)) {
            return 0;
        }
        return uint64(MercuryBase(aviation).aviationPoints(burnerAddressToTokenId(burner)));
    }

    function registerBot(address bot, bool register) external onlyOwner {
        validBidTacToeBots[bot] = register;
    }

    function cleanupDefaultQueue(address aviation) external onlyOwner {
        delete defaultGameQueue[aviation];
    }
}
