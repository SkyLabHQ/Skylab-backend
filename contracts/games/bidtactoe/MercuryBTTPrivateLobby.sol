// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MercuryBidTacToe.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";

interface IPrivateLobbyFactory {
    function clean(string memory) external;
    function setHasJoined(string memory name, bool joined) external;
    function hasJoined(address) external view returns (bool);
}

contract MercuryBTTPrivateLobby is MercuryGameBase {

    struct GameHistory {
        address winnerBurner;
        address loserBurner;
    }

    struct UserInfo {
        uint256 avatar;
        string  name;
    }

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) public gamePerPlayer;
    mapping(address => MercuryBidTacToe.GameParams) public paramsPerGame;
    mapping(address => MercuryBidTacToe.PlaneMetadata) public planeMetadataPerGame;
    mapping(address => UserInfo) public userInfo;

    // aviation to lobbies game queue
    mapping(address => address[]) lobbyGameQueue;
    mapping(address => uint256) lobbyGameIndex;
    mapping(address => address[]) lobbyOnGoingGames;
    mapping(address => uint256) lobbyOnGoingGamesIndex;

    //room related
    address public factory;
    address[] public players;
    GameHistory[] public gameHistory;
    address mercuryBidTacToe;
    string lobbyName;

    constructor(address _mercuryBidTacToe, string memory _lobbyName) {
        factory = msg.sender;
        lobbyName = _lobbyName;
        mercuryBidTacToe = _mercuryBidTacToe;

    }

    function setUserInfo(uint256 avatar, string memory userName) public {
        require(avatar >= 1 && avatar <= 16, "Private Lobby: avatar out of range");
        require(bytes(userName).length <= 10, "Private Lobby: name too long");
        userInfo[msg.sender] = UserInfo(avatar, userName);
    }

    function createLobby(MercuryBidTacToe.GameParams memory gameParams) external returns (address) {
        address newGame = LibBidTacToe.createGame(gameParams, msg.sender, address(this));
        address aviation = burnerAddressToAviation(msg.sender);
        paramsPerGame[newGame] = gameParams;
        planeMetadataPerGame[newGame] =
            MercuryBidTacToe.PlaneMetadata(getAviationLevel(msg.sender, aviation), getAviationPoints(msg.sender, aviation), 0, 0);
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        baseCreateRoom(newGame, aviation);
        return newGame;
    }

    function joinLobby(address gameAddress, address player2) external {
        require(gameExists[gameAddress], "PrivateLobby: lobby does not exist");
        require(gamePerPlayer[player2] == address(0), "PrivateLobby: player already created or queued for a game");
        require(
            isIdenticalAviation(LibBidTacToe.getPlayer1(gameAddress), player2),
            "PrivateLobby: aviation does not match"
        );

        LibBidTacToe.joinGame(gameAddress, player2);
        address aviation = burnerAddressToAviation(msg.sender);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2, aviation);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2, aviation);
        baseJoinRoom(gameAddress, aviation);
    }

    function deleteLobby(address lobby) external {
        require(gameExists[lobby], "PrivateLobby: lobby does not exist");
        require(
            planeMetadataPerGame[lobby].token2Level == 0 && planeMetadataPerGame[lobby].token2Points == 0,
            "PrivateLobby: the game is ongoing"
        );

        address aviation = burnerAddressToAviation(msg.sender);
        baseJoinRoom(lobby, aviation);
        baseQuitRoom(lobby, aviation);
        delete gameExists[lobby];
        delete paramsPerGame[lobby];
        delete planeMetadataPerGame[lobby];
        delete gamePerPlayer[msg.sender];
    }

    function baseCreateRoom(address newGame, address aviation) private {
        lobbyGameIndex[newGame] = lobbyGameQueue[aviation].length;
        lobbyGameQueue[aviation].push(newGame);
    }

    function baseJoinRoom(address lobby, address aviation) private {
        address swappedLobby = lobbyGameQueue[aviation][lobbyGameQueue[aviation].length - 1];
        uint256 index = lobbyGameIndex[lobby];
        lobbyGameQueue[aviation][index] = swappedLobby;
        lobbyGameQueue[aviation].pop();
        lobbyGameIndex[swappedLobby] = index;
        delete lobbyGameIndex[lobby];
        lobbyOnGoingGamesIndex[lobby] = lobbyOnGoingGames[aviation].length;
        lobbyOnGoingGames[aviation].push(lobby);
    }

    function baseQuitRoom(address game, address aviation) private {
        address swappedGame = lobbyOnGoingGames[aviation][lobbyOnGoingGames[aviation].length - 1];
        uint256 index = lobbyOnGoingGamesIndex[game];
        lobbyOnGoingGames[aviation][index] = swappedGame;
        lobbyOnGoingGames[aviation].pop();
        lobbyOnGoingGamesIndex[swappedGame] = index;
        delete lobbyOnGoingGamesIndex[game];
    }

    function joinPrivateLobby() external {
        require(!IPrivateLobbyFactory(factory).hasJoined(msg.sender), "PrivateLobby: player already joined");
        players.push(msg.sender);
        IPrivateLobbyFactory(factory).setHasJoined(lobbyName, true);
    }

    function quitPrivateLobby() external {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                players[i] = players[players.length - 1];
                players.pop();
            }
        }
        if (players.length == 0) {
            IPrivateLobbyFactory(factory).clean(lobbyName);
            IPrivateLobbyFactory(factory).setHasJoined(lobbyName, false);
        }
    }

    function handleWinLoss(address winnerBurner, address loserBurner) public {
        (bool succeed,) = mercuryBidTacToe.call(abi.encodeWithSignature("handleWinLoss(address,address)", winnerBurner, loserBurner));
        require(succeed, "PrivateLobby: handleWinLoss failed");
        address aviation = burnerAddressToAviation(winnerBurner);
        baseQuitRoom(msg.sender, aviation);
        gameHistory.push(GameHistory(winnerBurner, loserBurner));
    }

    function getAviationLevel(address burner, address aviation) internal view returns (uint64) {
        return uint64(MercuryBase(aviation).aviationLevels(burnerAddressToTokenId(burner)));
    }

    function getAviationPoints(address burner, address aviation) internal view returns (uint64) {
        return uint64(MercuryBase(aviation).aviationPoints(burnerAddressToTokenId(burner)));
    }
}
