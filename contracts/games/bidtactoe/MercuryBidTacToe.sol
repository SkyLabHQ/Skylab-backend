// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";
import {LibBidTacToe} from "./lib/LibBidTacToe.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";

contract MercuryBidTacToe is MercuryGameBase {
    struct GameParams {
        uint64 gridWidth;
        uint64 gridHeight;
        uint64 lengthToWin;
        uint64 initialBalance;
        uint128 gridMaxSelectionCount;
        uint128 gridSelectionStrategy;
        bool isBot;
        uint256 universalTimeout;
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
    mapping(address => GameParams) public paramsPerGame;
    mapping(address => PlaneMetadata) public planeMetadataPerGame;
    // collecton to default game queue
    mapping(address => address) public defaultGameQueue;
    mapping(address => bool) public validBidTacToeBots;
    mapping(address => mapping(address => uint256)) public joinDefaultQueueTime;
    mapping(address => address) public pvpRoom;

    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);
    event StartGame(address player1, address player2, address gameAddress);

    function initialize(address _protocol) public override {
        super.initialize(_protocol);
    }

    function createOrJoinDefault() external {
        require(!playerCreatedGameOrQueued(msg.sender), "MercuryBidTacToe: player already created or queued for a game");
        address aviation = burnerAddressToAviation(msg.sender);
        if (defaultGameQueue[aviation] == address(0)) {
            defaultGameQueue[aviation] = msg.sender;
            joinDefaultQueueTime[aviation][msg.sender] = block.timestamp;
        } else {
            address defaultPlayer = defaultGameQueue[aviation];
            if (burnerAddressToAviation(defaultPlayer) != aviation) {
                defaultGameQueue[aviation] = msg.sender;
                joinDefaultQueueTime[aviation][msg.sender] = block.timestamp;
            } else {
                delete defaultGameQueue[aviation];
                address gameAddress = createGame(LibBidTacToe.defaultParams(), defaultPlayer);
                joinGame(gameAddress, msg.sender);
                emit StartGame(defaultPlayer, msg.sender, gameAddress);
                delete joinDefaultQueueTime[aviation][defaultPlayer];
            }
        }
    }

    function playWithBotAfterDefaultQueueTimer(address aviation, address bot) public {
        require(componentIndex().isValidAviation(aviation), "MercuryBidTacToe: invalid aviation");
        require(defaultGameQueue[aviation] == msg.sender, "MercuryBidTacToe: msg.sender is not in default queue");
        require(
            joinDefaultQueueTime[aviation][msg.sender] + 45 seconds <= block.timestamp,
            "MercuryBidTacToe: time not reached"
        );
        uint256 tokenId = burnerAddressToTokenId(msg.sender);
        require(isApprovedForGame(tokenId, MercuryBase(aviation)), "MercuryBidTacToe: not approved for game");
        delete joinDefaultQueueTime[aviation][msg.sender];
        delete defaultGameQueue[aviation];
        createBotGame(bot);
    }

    function createBotGame(address bot) public {
        require(validBidTacToeBots[bot], "MercuryBidTacToe: bot is a valid bot");
        address gameAddress = createGame(LibBidTacToe.defaultBotParams(), msg.sender);
        LibBidTacToe.joinGame(gameAddress, bot);
    }

    function createGame(GameParams memory gameParams, address player1) internal returns (address) {
        require(!playerCreatedGameOrQueued(player1), "MercuryBidTacToe: player already created or queued for a game");

        address newGame = LibBidTacToe.createGame(gameParams, player1, address(this));
        address aviation = burnerAddressToAviation(player1);
        paramsPerGame[newGame] = gameParams;
        planeMetadataPerGame[newGame] =
            PlaneMetadata(getAviationLevel(player1, aviation), getAviationPoints(player1, aviation), 0, 0);
        gameExists[newGame] = true;
        gamePerPlayer[player1] = newGame;
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
        address aviation = burnerAddressToAviation(player2);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2, aviation);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2, aviation);
    }

    function createPvPRoom(GameParams memory gameParams) external {
        address aviation = burnerAddressToAviation(msg.sender);
        pvpRoom[msg.sender] = aviation;
        createGame(gameParams, msg.sender);
    }

    // to discuss: usr address instead of referral code to join room
    // pvp room only apply on 1v1 game, so using host address as key to track room info
    // if we want referral code to enable private room feature(passward as key), i think we can use ECDSA algorithm to generate a code in the frond end.
    // and add decoding referral code in the contract to check if this message is signed by room hoster.
    function joinPvPRoom(address player1) external {
        address aviation = burnerAddressToAviation(msg.sender);
        require(aviation == pvpRoom[player1] && msg.sender != player1, "MercuryBidTacToe: aviation does not match");
        address gameAddress = gamePerPlayer[player1];
        joinGame(gameAddress, msg.sender);
        emit StartGame(player1, msg.sender, gameAddress);
        delete pvpRoom[player1];
    }

    function withdrawFromQueue() external {
        address aviation = burnerAddressToAviation(msg.sender);
        require(msg.sender == defaultGameQueue[aviation], "MercuryBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue[aviation];
        unapproveForGame(burnerAddressToTokenId(msg.sender), MercuryBase(aviation));
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
        delete gamePerPlayer[winnerBurner];
        delete gamePerPlayer[loserBurner];
        if (burnerAddressToAviation(winnerBurner) != address(0)) {
            MercuryBase aviation = MercuryBase(burnerAddressToAviation(winnerBurner));
            uint256 winnerTokenId = cleanUp(winnerBurner, aviation);
            uint256 loserTokenId = cleanUp(loserBurner, aviation);
            emit WinGame(winnerTokenId, aviation.ownerOf(winnerTokenId));
            emit LoseGame(loserTokenId, aviation.ownerOf(loserTokenId));
            aviation.aviationMovePoints(winnerTokenId, loserTokenId);
        }
        if (gameExists[msg.sender]) {
            delete gameExists[msg.sender];
        }
    }

    function handleBotWinLoss(address playerBurner, bool playerWon) external {
        require(gameExists[msg.sender], "MercuryBidTacToe: msg.sender is not a game");
        require(
            gamePerPlayer[playerBurner] == msg.sender, "MercuryBidTacToe: burner address does not belong to this game"
        );
        delete gamePerPlayer[playerBurner];
        delete gameExists[msg.sender];
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
    }

    function cleanUp(address burner, MercuryBase aviation) private returns (uint256) {
        uint256 tokenId = burnerAddressToTokenId(burner);
        unapproveForGame(tokenId, aviation);
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
}
