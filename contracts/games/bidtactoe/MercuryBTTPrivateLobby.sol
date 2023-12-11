// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MercuryBidTacToe.sol";
import "../../aviation/base/MercuryBase.sol";
import {LibBidTacToe} from "./lib/LibBidTacToe.sol";

contract MercuryBTTPrivateLobby {
    struct GameHistory {
        address winnerBurner;
        address loserBurner;
    }

    struct UserInfo {
        uint256 avatar;
        string name;
    }

    // Dynamic game data
    mapping(address => UserInfo) public userInfo;
    address[] public players;
    GameHistory[] public gameHistory;
    mapping(address => uint256) public winCountPerPlayer;
    mapping(address => uint256) public loseCountPerPlayer;

    // aviation to lobbies game queue
    address[] lobbyGameQueue;
    mapping(address => uint256) lobbyGameIndex;
    address[] lobbyOnGoingGames;
    mapping(address => uint256) lobbyOnGoingGamesIndex;

    // Static data
    MercuryBidTacToe mercuryBidTacToe;
    address public lobbyAviation;
    address public admin;
    string public lobbyName;

    modifier isActiveLobbyAndCorrectAviation() {
        require(
            mercuryBidTacToe.activeLobbyPerPlayer(msg.sender) == address(this),
            "MercuryBTTPrivateLobby: not active lobby"
        );
        require(
            mercuryBidTacToe.burnerAddressToAviation(msg.sender) == lobbyAviation,
            "MercuryBTTPrivateLobby: player aviation is not the same as lobby aviation"
        );
        _;
    }

    constructor(string memory _lobbyName, address _admin) {
        lobbyName = _lobbyName;
        mercuryBidTacToe = MercuryBidTacToe(msg.sender);
        admin = _admin;
        lobbyAviation = mercuryBidTacToe.burnerAddressToAviation(admin);

        joinPrivateLobby();
    }

    function setUserInfo(uint256 avatar, string memory userName) public isActiveLobbyAndCorrectAviation {
        require(avatar >= 1 && avatar <= 16, "MercuryBTTPrivateLobby: avatar out of range");
        require(bytes(userName).length <= 10, "MercuryBTTPrivateLobby: name too long");
        userInfo[msg.sender] = UserInfo(avatar, userName);
    }

    function createRoom(MercuryBidTacToe.GameParams memory gameParams)
        external
        isActiveLobbyAndCorrectAviation
        returns (address)
    {
        address newGame = mercuryBidTacToe.createGameInPrivateLobby(gameParams);
        baseCreateRoom(newGame);
        return newGame;
    }

    function joinRoom(address gameAddress, address player2) external isActiveLobbyAndCorrectAviation {
        mercuryBidTacToe.joinGameInPrivateLobby(gameAddress, player2);
        baseJoinRoom(gameAddress);
    }

    function deleteRoom(address room) external isActiveLobbyAndCorrectAviation {
        require(
            msg.sender == LibBidTacToe.getPlayer1(room) || msg.sender == admin,
            "MercuryBTTPrivateLobby: only player1 or admin can delete room"
        );
        mercuryBidTacToe.deleteGameInPrivateLobby(room);
        baseJoinRoom(room);
        baseQuitRoom(room);
    }

    function baseCreateRoom(address newGame) private {
        lobbyGameIndex[newGame] = lobbyGameQueue.length;
        lobbyGameQueue.push(newGame);
    }

    function baseJoinRoom(address lobby) private {
        address swappedRoom = lobbyGameQueue[lobbyGameQueue.length - 1];
        uint256 index = lobbyGameIndex[lobby];
        lobbyGameQueue[index] = swappedRoom;
        lobbyGameQueue.pop();
        lobbyGameIndex[swappedRoom] = index;
        delete lobbyGameIndex[lobby];
        lobbyOnGoingGamesIndex[lobby] = lobbyOnGoingGames.length;
        lobbyOnGoingGames.push(lobby);
    }

    function baseQuitRoom(address game) private {
        address swappedGame = lobbyOnGoingGames[lobbyOnGoingGames.length - 1];
        uint256 index = lobbyOnGoingGamesIndex[game];
        lobbyOnGoingGames[index] = swappedGame;
        lobbyOnGoingGames.pop();
        lobbyOnGoingGamesIndex[swappedGame] = index;
        delete lobbyOnGoingGamesIndex[game];
    }

    function joinPrivateLobby() public {
        players.push(msg.sender);
        mercuryBidTacToe.setActiveLobby(msg.sender);
    }

    function quitPrivateLobby() external isActiveLobbyAndCorrectAviation {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                players[i] = players[players.length - 1];
                players.pop();
            }
        }
        mercuryBidTacToe.deactiveLobbyForPlayer(msg.sender);
        if (players.length == 0) {
            mercuryBidTacToe.deletePrivateLobby(lobbyName);
        }
    }

    function handleWinLoss(address winnerBurner, address loserBurner) public {
        baseQuitRoom(msg.sender);
        gameHistory.push(GameHistory(winnerBurner, loserBurner));
        winCountPerPlayer[winnerBurner] += 1;
        loseCountPerPlayer[loserBurner] += 1;
        mercuryBidTacToe.handleWinLoss(winnerBurner, loserBurner);
    }
}
