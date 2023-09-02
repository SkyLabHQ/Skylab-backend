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
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        return newGame;
    }

    function joinLobby(address lobby) external {
        require(gameExists[lobby], "SkylabBidTacToe: lobby does not exist");
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        deployer.joinGame(lobby, msg.sender);
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
            deployer.joinGame(gameAddress, defaultGameQueue);
            gamePerPlayer[defaultGameQueue] = gameAddress;
            delete defaultGameQueue;
        }
    }

    function withdrawFromQueue() external {
        require(msg.sender == defaultGameQueue, "SkylabBidTacToe: msg.sender is not in default queue");
        delete defaultGameQueue;
        _skylabBase.aviationUnlock(burnerAddressToTokenId[msg.sender]);
    }

    function handleWin(address burner) external {
        require(gameExists[msg.sender], "SkylabBidTacToe: msg.sender is not a game");
        require(gamePerPlayer[burner] == msg.sender, "SkylabBidTacToe: address does not belong to this game");
        uint tokenId = burnerAddressToTokenId[burner];
        if (_skylabBase._aviationLevels(tokenId) == 1) {
            _skylabBase.aviationGainCounter(tokenId);
        }
        _skylabBase.aviationUnlock(tokenId);
        emit WinGame(tokenId, _skylabBase.ownerOf(tokenId));
        _skylabBase.aviationGainCounter(tokenId);
        delete gamePerPlayer[burner];
        delete gameExists[msg.sender];
        delete paramsPerGame[msg.sender];
    }

    function handleLoss(address burner) external {
        require(gameExists[msg.sender], "SkylabBidTacToe: msg.sender is not a game");
        require(gamePerPlayer[burner] == msg.sender, "SkylabBidTacToe: address does not belong to this game");
        uint tokenId = burnerAddressToTokenId[burner];
        _skylabBase.aviationUnlock(tokenId);
        emit LoseGame(tokenId, _skylabBase.ownerOf(tokenId));
        _skylabBase.aviationLevelDown(tokenId, 1);
        delete gamePerPlayer[burner];
        delete gameExists[msg.sender];
        delete paramsPerGame[msg.sender];
    }

    // =====================
    // Approval
    // =====================
    function isApprovedForGame(address to, uint tokenId) public virtual view returns (bool) {
        return _skylabBase.isApprovedOrOwner(to, tokenId) || _gameApprovals[tokenId] == to;
    }

    function approveForGame(address to, uint tokenId) public virtual {
        require(isApprovedForGame(msg.sender, tokenId), "SkylabGameBase: caller is not token owner or approved");
        _gameApprovals[tokenId] = to;
        burnerAddressToTokenId[to] = tokenId;
    }

    function unapproveForGame(uint tokenId) public virtual {
        require(isApprovedForGame(msg.sender, tokenId), "SkylabGameBase: caller is not token owner or approved");
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