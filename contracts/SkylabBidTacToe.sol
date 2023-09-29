// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import { SkylabBidTacToeDeployer } from "./SkylabBidTacToeDeployer.sol";
import { SkylabBase } from "./SkylabBase.sol";


contract SkylabBidTacToe is Ownable {
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

    SkylabBase internal _skylabBase;
    SkylabBidTacToeDeployer private deployer;
    // token id => address
    mapping(uint256 => address) private _gameApprovals;

    // Mapping for displays
    mapping(address => uint) public burnerAddressToTokenId;

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) public gamePerPlayer;
    mapping(address => GameParams) public paramsPerGame;
    mapping(address => PlaneMetadata) public planeMetadataPerGame;

    address[] public lobbyGameQueue;
    mapping(address => uint) private lobbyGameIndex;
    address public defaultGameQueue;
    
    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    constructor(address skylabBaseAddress, address deployerAddress) {
        _skylabBase = SkylabBase(skylabBaseAddress);
        deployer = SkylabBidTacToeDeployer(deployerAddress);
    }

    function createLobby(uint64 gridWidth, uint64 gridHeight, uint64 lengthToWin, uint64 initialBalance) external {
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        GameParams memory gameParams = GameParams(gridWidth, gridHeight, lengthToWin, initialBalance);
        address newGame = createGame(gameParams);
        lobbyGameIndex[newGame] = lobbyGameQueue.length;
        lobbyGameQueue.push(newGame);
    }

    function createGame(GameParams memory gameParams) internal returns (address) {
        require(gamePerPlayer[msg.sender] == address(0), "SkylabBidTacToe: a game has already been created by caller");
        address newGame = deployer.createGame(gameParams, msg.sender, address(this));
        
        paramsPerGame[newGame] = gameParams;
        planeMetadataPerGame[newGame] = PlaneMetadata(getAviationLevel(msg.sender), getAviationPoints(msg.sender), 0, 0);
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        return newGame;
    }

    function joinLobby(address lobby) external {
        require(gameExists[lobby], "SkylabBidTacToe: lobby does not exist");
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        joinGame(lobby, msg.sender);
        gamePerPlayer[msg.sender] = lobby;

        address swappedLobby = lobbyGameQueue[lobbyGameQueue.length - 1];
        uint index = lobbyGameIndex[lobby];
        lobbyGameQueue[index] = swappedLobby;
        lobbyGameQueue.pop();
        lobbyGameIndex[swappedLobby] = index;
        delete lobbyGameIndex[lobby];
    }

    function createOrJoinDefault() external {
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        if (defaultGameQueue == address(0)) {
            defaultGameQueue = msg.sender;
        } else {
            address gameAddress = createGame(deployer.defaultParams());
            joinGame(gameAddress, defaultGameQueue);
            delete defaultGameQueue;
        }
    }

    function joinGame(address gameAddress, address player2) internal {
        deployer.joinGame(gameAddress, player2);
        gamePerPlayer[player2] = gameAddress;
        planeMetadataPerGame[gameAddress].token2Level = getAviationLevel(player2);
        planeMetadataPerGame[gameAddress].token2Points = getAviationPoints(player2);
    }

    function withdrawFromQueue() external {
        require(msg.sender == defaultGameQueue, "SkylabBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue;
        _skylabBase.aviationUnlock(burnerAddressToTokenId[msg.sender]);
    }

    function handleWinLoss(address winnerBurner, address loserBurner) external {
        require(gameExists[msg.sender], "SkylabBidTacToe: msg.sender is not a game");
        require(gamePerPlayer[winnerBurner] == msg.sender && gamePerPlayer[loserBurner] == msg.sender , "SkylabBidTacToe: burner addresses does not belong to this game");
        uint winnerTokenId = cleanUp(winnerBurner);
        uint loserTokenId = cleanUp(loserBurner);
        emit WinGame(winnerTokenId, _skylabBase.ownerOf(winnerTokenId));
        emit LoseGame(loserTokenId, _skylabBase.ownerOf(loserTokenId));
        _skylabBase.aviationMovePoints(winnerTokenId, loserTokenId);
        delete gameExists[msg.sender];
        delete paramsPerGame[msg.sender];
    }

    function cleanUp(address burner) private returns (uint) {
        uint tokenId = burnerAddressToTokenId[burner];
        _skylabBase.aviationUnlock(tokenId);
        delete gamePerPlayer[burner];
        return tokenId;
    }

    function getAviationLevel(address burner) internal view returns (uint64) {
        return uint64(_skylabBase._aviationLevels(burnerAddressToTokenId[burner]));
    }

    function getAviationPoints(address burner) internal view returns (uint64) {
        return uint64(_skylabBase._aviationPoints(burnerAddressToTokenId[burner]));
    }

    // =====================
    // Approval
    // =====================
    function isApprovedForGame(address to, uint tokenId) public virtual view returns (bool) {
        return _skylabBase.isApprovedOrOwner(to, tokenId) || _gameApprovals[tokenId] == to;
    }

    function approveForGame(address to, uint tokenId) public virtual {
        require(isApprovedForGame(msg.sender, tokenId), "SkylabGameBase: caller is not token owner or approved");
        require(!_skylabBase.isAviationLocked(tokenId), "SkylabGameBase: token has been locked");
        _gameApprovals[tokenId] = to;
        burnerAddressToTokenId[to] = tokenId;
    }

    function unapproveForGame(uint tokenId) public virtual {
        require(isApprovedForGame(msg.sender, tokenId), "SkylabGameBase: caller is not token owner or approved");
        require(!_skylabBase.isAviationLocked(tokenId), "SkylabGameBase: token has been locked");
        delete _gameApprovals[tokenId];
        delete burnerAddressToTokenId[msg.sender];
    }

    // =====================
    // Utils
    // ===================== 
    function registerSkylabBase(address skylabBaseAddress) external onlyOwner {
        _skylabBase = SkylabBase(skylabBaseAddress);
    }

    function registerSkylabBidTacToeDeployer(address deployerAddress) external onlyOwner {
        deployer = SkylabBidTacToeDeployer(deployerAddress);
    }

}