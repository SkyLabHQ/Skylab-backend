// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";
import {LibBidTacToe} from "./lib/LibBidTacToe.sol";
import {MercuryPilots} from "../../protocol/MercuryPilots.sol";

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

    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    function createLobby(
        uint64 gridWidth,
        uint64 gridHeight,
        uint64 lengthToWin,
        uint64 initialBalance,
        address aviation
    ) external {
        MercuryBase(aviation).aviationLock(burnerAddressToTokenId(msg.sender));
        GameParams memory gameParams = GameParams(gridWidth, gridHeight, lengthToWin, initialBalance);
        address newGame = createGame(gameParams, aviation);
        super.baseCreateLobby(newGame, aviation);
    }

    function createGame(GameParams memory gameParams, address aviation) internal returns (address) {
        require(gamePerPlayer[msg.sender] == address(0), "MercuryBidTacToe: a game has already been created by caller");
        address newGame = LibBidTacToe.createGame(gameParams, msg.sender, address(this), aviation);

        paramsPerGame[newGame] = gameParams;
        planeMetadataPerGame[newGame] =
            PlaneMetadata(getAviationLevel(msg.sender, aviation), getAviationPoints(msg.sender, aviation), 0, 0);
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        return newGame;
    }

    function joinLobby(address lobby, address aviation) external {
        require(isIdenticalAviation(lobby, aviation), "MercuryBidTacToe: aviation does not match");
        require(gameExists[lobby], "MercuryBidTacToe: lobby does not exist");
        MercuryBase(aviation).aviationLock(burnerAddressToTokenId(msg.sender));
        joinGame(lobby, msg.sender, aviation);
        super.baseJoinLobby(lobby, aviation);
    }

    function createOrJoinDefault(address aviation) external {
        MercuryBase(aviation).aviationLock(burnerAddressToTokenId(msg.sender));
        if (defaultGameQueue[aviation] == address(0)) {
            defaultGameQueue[aviation] = msg.sender;
        } else {
            address gameAddress = createGame(LibBidTacToe.defaultParams(), aviation);
            super.baseCreateLobby(gameAddress, aviation);
            joinGame(gameAddress, defaultGameQueue[aviation], aviation);
            super.baseJoinLobby(gameAddress, aviation);
            gamePerPlayer[defaultGameQueue[aviation]] = gameAddress;
            delete defaultGameQueue[aviation];
        }
    }

    function joinGame(address gameAddress, address player2, address aviation) internal {
        LibBidTacToe.joinGame(gameAddress, player2);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2, aviation);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2, aviation);
    }

    function withdrawFromQueue(address aviation) external {
        require(msg.sender == defaultGameQueue[aviation], "MercuryBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue[aviation];
        MercuryBase(aviation).aviationUnlock(burnerAddressToTokenId(msg.sender));
    }

    function handleWinLoss(address winnerBurner, address loserBurner, MercuryBase aviation) external {
        require(gameExists[msg.sender], "MercuryBidTacToe: msg.sender is not a game");
        require(
            gamePerPlayer[winnerBurner] == msg.sender && gamePerPlayer[loserBurner] == msg.sender,
            "MercuryBidTacToe: burner addresses does not belong to this game"
        );
        uint256 winnerTokenId = cleanUp(winnerBurner, aviation);
        uint256 loserTokenId = cleanUp(loserBurner, aviation);
        super.baseQuitLobby(msg.sender, address(aviation));
        emit WinGame(winnerTokenId, aviation.ownerOf(winnerTokenId));
        emit LoseGame(loserTokenId, aviation.ownerOf(loserTokenId));
        aviation.aviationMovePoints(winnerTokenId, loserTokenId);
        delete gameExists[msg.sender];
        delete paramsPerGame[msg.sender];
    }

    function cleanUp(address burner, MercuryBase aviation) private returns (uint256) {
        uint256 tokenId = burnerAddressToTokenId(burner);
        address user = aviation.ownerOf(tokenId);
        pilot().increasePilotSessions(user);
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
}
