// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import { BidTacToe } from "./BidTacToe.sol";
import { SkylabBidTacToeParamVerifier } from "./SkylabBidTacToeParamVerifier.sol";
import { SkylabBase } from "./SkylabBase.sol";


contract SkylabBidTacToe is Ownable {
    struct GameParams {
        uint gridWidth;
        uint gridHeight; 
        uint lengthToWin; 
        uint initialBalance;
    }

    SkylabBase internal _skylabBase;
    SkylabBidTacToeParamVerifier private verifier;
    // token id => address
    mapping(uint256 => address) private _gameApprovals;

    // Mapping for displays
    mapping(address => uint) public burnerAddressToTokenId;

    // Dynamic game data
    mapping(address => bool) private gameExists;
    mapping(address => address) private gamePerPlayer;
    mapping(address => GameParams) public paramsPerGame;

    address[] public lobbyGameQueue;
    mapping(address => uint) private lobbyGameIndex;
    address public defaultGameQueue;
    
    event WinGame(uint256 indexed tokenId, address indexed user);
    event LoseGame(uint256 indexed tokenId, address indexed user);

    constructor(address skylabBaseAddress, address verifierAddress) {
        _skylabBase = SkylabBase(skylabBaseAddress);
        verifier = SkylabBidTacToeParamVerifier(verifierAddress);
    }

    function createLobby(uint gridWidth, uint gridHeight, uint lengthToWin, uint initialBalance) external {
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        GameParams memory gameParams = GameParams(gridWidth, gridHeight, lengthToWin, initialBalance);
        address newGame = createGame(gameParams);
        lobbyGameIndex[newGame] = lobbyGameQueue.length;
        lobbyGameQueue.push(newGame);
    }

    function createGame(GameParams memory gameParams) internal returns (address) {
        require(gamePerPlayer[msg.sender] == address(0), "SkylabBidTacToe: a game has already been created by caller");
        verifier.verify(gameParams);
        address newGame = address(new BidTacToe(gameParams, msg.sender, address(this)));
        
        paramsPerGame[newGame] = gameParams;
        gameExists[newGame] = true;
        gamePerPlayer[msg.sender] = newGame;
        return newGame;
    }

    function joinLobby(address lobby) external {
        require(gameExists[lobby], "SkylabBidTacToe: lobby does not exist");
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        BidTacToe existingGame = BidTacToe(lobby);
        existingGame.joinGame(msg.sender);
        gamePerPlayer[msg.sender] = lobby;

        address swappedLobby = lobbyGameQueue[lobbyGameQueue.length - 1];
        uint index = lobbyGameIndex[lobby];
        lobbyGameQueue[index] = swappedLobby;
        lobbyGameQueue.pop();
        lobbyGameIndex[swappedLobby] = index;
        delete lobbyGameIndex[lobby];
    }

    function createOrJoinDefault() external returns (address) {
        _skylabBase.aviationLock(burnerAddressToTokenId[msg.sender]);
        if (defaultGameQueue == address(0)) {
            defaultGameQueue = createGame(verifier.defaultParams());
            return defaultGameQueue;
        } else {
            BidTacToe existingGame = BidTacToe(defaultGameQueue);
            existingGame.joinGame(msg.sender);
            gamePerPlayer[msg.sender] = defaultGameQueue;
            delete defaultGameQueue;
            return address(existingGame);
        }
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
    }

    function handleLoss(address burner) external {
        require(gameExists[msg.sender], "SkylabBidTacToe: msg.sender is not a game");
        require(gamePerPlayer[burner] == msg.sender, "SkylabBidTacToe: address does not belong to this game");
        uint tokenId = burnerAddressToTokenId[burner];
        _skylabBase.aviationUnlock(tokenId);
        emit LoseGame(tokenId, _skylabBase.ownerOf(tokenId));
        _skylabBase.aviationLevelDown(tokenId, 1);
        delete gamePerPlayer[burner];
    }

    // =====================
    // Approval
    // =====================
    function isApprovedForGame(uint tokenId) public virtual view returns (bool) {
        return _skylabBase.isApprovedOrOwner(msg.sender, tokenId) || _gameApprovals[tokenId] == msg.sender;
    }

    function approveForGame(address to, uint tokenId) public virtual {
        require(isApprovedForGame(tokenId), "SkylabGameBase: caller is not token owner or approved");
        _gameApprovals[tokenId] = to;
        burnerAddressToTokenId[to] = tokenId;
    }

    function unapproveForGame(uint tokenId) public virtual {
        require(isApprovedForGame(tokenId), "SkylabGameBase: caller is not token owner or approved");
        delete _gameApprovals[tokenId];
        delete burnerAddressToTokenId[msg.sender];
    }

    // =====================
    // Utils
    // ===================== 
    function registerSkylabBase(address skylabBaseAddress) external onlyOwner {
        _skylabBase = SkylabBase(skylabBaseAddress);
    }

    function registerSkylabBidTacToeParamVerifier(address verifierAddress) external onlyOwner {
        verifier = SkylabBidTacToeParamVerifier(verifierAddress);
    }

}