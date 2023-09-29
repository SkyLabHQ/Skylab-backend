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

    constructor(address _protocol) MercuryGameBase(_protocol) {}

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) public gamePerPlayer;
    mapping(address => GameParams) public paramsPerGame;
    mapping(address => address) public gameToCollection;
    // collecton to default game queue
    mapping(address => address) public defaultGameQueue;

    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    function createLobby(
        uint64 gridWidth,
        uint64 gridHeight,
        uint64 lengthToWin,
        uint64 initialBalance,
        address collection
    ) external {
        MercuryBase(collection).aviationLock(burnerAddressToTokenId(msg.sender));
        GameParams memory gameParams = GameParams(gridWidth, gridHeight, lengthToWin, initialBalance);
        address newGame = createGame(gameParams);
        gameToCollection[newGame] = collection;
        super.baseCreateLobby(newGame, collection);
    }

    function createGame(GameParams memory gameParams) internal returns (address) {
        require(gamePerPlayer[msg.sender] == address(0), "MercuryBidTacToe: a game has already been created by caller");
        address newGame = LibBidTacToe.createGame(gameParams, msg.sender, address(this));

        paramsPerGame[newGame] = gameParams;
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        return newGame;
    }

    function joinLobby(address lobby, address collection) external {
        require(gameToCollection[lobby] == collection, "MercuryBidTacToe: collection does not match");
        require(gameExists[lobby], "MercuryBidTacToe: lobby does not exist");
        MercuryBase(collection).aviationLock(burnerAddressToTokenId(msg.sender));
        LibBidTacToe.joinGame(lobby, msg.sender);
        gamePerPlayer[msg.sender] = lobby;
        super.baseJoinLobby(lobby, collection);
    }

    function createOrJoinDefault(address collection) external {
        MercuryBase(collection).aviationLock(burnerAddressToTokenId(msg.sender));
        if (defaultGameQueue[collection] == address(0)) {
            defaultGameQueue[collection] = msg.sender;
        } else {
            address gameAddress = createGame(LibBidTacToe.defaultParams());
            LibBidTacToe.joinGame(gameAddress, defaultGameQueue[collection]);
            gameToCollection[gameAddress] = collection;
            gamePerPlayer[defaultGameQueue[collection]] = gameAddress;
            delete defaultGameQueue[collection];
        }
    }

    function withdrawFromQueue(address collection) external {
        require(msg.sender == defaultGameQueue[collection], "MercuryBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue[collection];
        MercuryBase(collection).aviationUnlock(burnerAddressToTokenId(msg.sender));
    }

    function handleWinLoss(address winnerBurner, address loserBurner, MercuryBase collection) external {
        require(gameExists[msg.sender], "MercuryBidTacToe: msg.sender is not a game");
        require(
            gamePerPlayer[winnerBurner] == msg.sender && gamePerPlayer[loserBurner] == msg.sender,
            "MercuryBidTacToe: burner addresses does not belong to this game"
        );
        uint256 winnerTokenId = cleanUp(winnerBurner, collection);
        uint256 loserTokenId = cleanUp(loserBurner, collection);
        emit WinGame(winnerTokenId, collection.ownerOf(winnerTokenId));
        emit LoseGame(loserTokenId, collection.ownerOf(loserTokenId));
        collection.aviationMovePoints(winnerTokenId, loserTokenId);
        delete gameExists[msg.sender];
        delete paramsPerGame[msg.sender];
    }

    function cleanUp(address burner, MercuryBase collection) private returns (uint256) {
        uint256 tokenId = burnerAddressToTokenId(burner);
        collection.aviationUnlock(tokenId);
        delete gamePerPlayer[burner];
        return tokenId;
    }
}
