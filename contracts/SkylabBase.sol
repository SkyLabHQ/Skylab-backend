// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import { SkylabMetadata } from "./SkylabMetadata.sol";
import { SkylabResources } from "./SkylabResources.sol";

contract SkylabBase is ERC721Enumerable, Ownable {
    using Strings for uint;

    uint constant _maxLevel = 16;

    // per token data
    mapping(uint => uint) public _aviationLevels;
    mapping(uint => uint) public _aviationPoints;
    mapping(uint => bool) public _aviationTradeLock;
    mapping(uint => uint) public _aviationPilotIds;
    mapping(uint => address) public _aviationPilotAddresses;

    uint internal _nextTokenID = 1;
    string internal _metadataBaseURI;
    mapping(address => mapping(uint => uint)) internal _pilotToToken;

    // addresses
    SkylabResources internal _skylabResources;
    SkylabMetadata internal _skylabMetadata;
    mapping(address => bool) internal _gameAddresses;
    mapping(address => string) internal _pilotAddressesToNames;
    mapping(address => string) internal _pilotAddressesToUrls;

    modifier onlyGameAddresses() {
        require(_gameAddresses[_msgSender()], "SkylabBase: msg.sender is not a valid game address");
        _;
    }

    constructor(string memory baseURI, string memory name, string memory symbol) ERC721(name, symbol) {
        _metadataBaseURI = baseURI;
    }

    // ====================
    // Mint 
    // ====================

    // function publicMint(address memory to) external {
    //     _safeMint(to, __nextTokenID);
    //     _aviationLevels[__nextTokenID] = 1;
    //     __nextTokenID++;
    // }


    // function addPilot(uint tokenId, uint pilotId, address pilotAddress) external {
    //     address pilotOwner = ERC721(pilotAddress).ownerOf(pilotId);
    //     require(_msgSender() == pilotOwner || ERC721(pilotAddress).isApprovedForAll(pilotOwner, _msgSender()) || ERC721(pilotAddress).getApproved(pilotId) == _msgSender(), "SkylabBase: pilot not owned by msg sender");
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    //     require(_pilotAddressesToNames[pilotAddress] != "", "SkylabBase: unregistered pilotAddress");
    //     require(_pilotToToken[pilotAddress][pilotId] == 0, "SkylabBase: pilot already added");
    //     _aviationPilotIds[tokenId] = pilotId;
    //     _aviationPilotAddresses[tokenId] = pilotAddress;
    //     _pilotToToken[pilotAddress][pilotId] = tokenId;
    // }

    // ====================
    // Aviation level 
    // ====================
    function aviationMovePoints(uint winnerTokenId, uint loserTokenId) external onlyGameAddresses {
        require(_exists(winnerTokenId), "SkylabBase: nonexistent token");
        require(_exists(loserTokenId), "SkylabBase: nonexistent token");

        uint pointsToMove = _aviationPoints[winnerTokenId] >= (uint(_aviationPoints[loserTokenId] + 1) / uint(2)) ? (uint(_aviationPoints[loserTokenId] + 1) / uint(2)) : _aviationPoints[winnerTokenId];
        _aviationPoints[winnerTokenId] += pointsToMove;
        if (pointsToMove >= _aviationPoints[loserTokenId]) {
            _aviationPoints[loserTokenId] = 0;
        } else {
            _aviationPoints[loserTokenId] -= pointsToMove;
        }

        updateLevel(winnerTokenId);
        updateLevel(loserTokenId);

        if (_aviationPoints[loserTokenId] == 0) {
           burnAviation(loserTokenId);
        }
    }

    function updateLevel(uint tokenId) private {
        for (uint i = 0; i <= _maxLevel; i++) {
            if (2**i > _aviationPoints[tokenId]) {
                _aviationLevels[tokenId] = i;
                return;
            }
        }
        _aviationLevels[tokenId] = _maxLevel;
    }

    function burnAviation(uint tokenId) private {
        _burn(tokenId);
        _pilotToToken[_aviationPilotAddresses[tokenId]][_aviationPilotIds[tokenId]] = 0;
    }

    // ====================
    // MISC
    // ====================
    function requestResourcesForGame(address from,
        address game,
        uint256[] memory ids,
        uint256[] memory amounts) external onlyGameAddresses {
        _skylabResources.burn(from, ids, amounts);
        _skylabResources.mintBatch(game, ids, amounts, "");
    }

    function refundResourcesFromGame(address game,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts) external onlyGameAddresses {
        _skylabResources.burn(game, ids, amounts);
        _skylabResources.mintBatch(to, ids, amounts, "");
    }

    function aviationLock(uint tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(!_aviationTradeLock[tokenId], "SkylabBase: aviation locked");
        _aviationTradeLock[tokenId] = true;
    }

    function aviationUnlock(uint tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(_aviationTradeLock[tokenId], "SkylabBase: aviation not locked");
        _aviationTradeLock[tokenId] = false;
    }

    function isAviationLocked(uint tokenId) external view virtual onlyGameAddresses returns (bool) {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        return _aviationTradeLock[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) override internal virtual {
        require(!_aviationTradeLock[tokenId], "SkylabBase: token is locked");
        super._transfer(from, to, tokenId);
    } 

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }


    // // ====================
    // // Factory Mechanism
    // // ====================

    // // Stake a Factory so that it's ready to generate fuel and become prone to attack
    // function stakeFactory(uint tokenId) external _isApprovedOrOwner {

    // }

    // function unstakeFactory(uint tokenId) external _isApprovedOrOwner {

    // }

    // // If the factory has been staked for more than 7 days, claim fuel as rewards
    // function generateFuel(uint tokenId) external _isApprovedOrOwner {

    // }

    // // Defend a factory with certain amount of shields
    // function shieldFactory(uint tokenId, uint shieldCount) external _isApprovedOrOwner {

    // }

    // // Attack a random factory
    // function attackFactory(uint bombCount) external _isApprovedOrOwner {

    // }

    // =======================
    // Admin Utility
    // =======================
    function registerMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataBaseURI = metadataURI;
    }

    function registerResourcesAddress(address resourcesAddress) external onlyOwner {
        _skylabResources = SkylabResources(resourcesAddress);
    }

    function registerMetadataAddress(address metadataAddress) external onlyOwner {
        _skylabMetadata = SkylabMetadata(metadataAddress);
    }

    function registerGameAddress(address gameAddress, bool enable) external onlyOwner {
        _gameAddresses[gameAddress] = enable;
    }
    
    function registerPilotAddress(address pilotAddress, string memory pilotCollectionName, string memory baseUrl) external onlyOwner {
        _pilotAddressesToNames[pilotAddress] = pilotCollectionName;
        _pilotAddressesToUrls[pilotAddress] = baseUrl;
    }

    // // Set the number of shields generated when an Aviation of a specified level dies in a collision
    // function setShieldYield(uint level) external onlyOwner {

    // }

    // // Set the level of an Aviation for allowlist mint purpose
    // function setAviationLevel(uint tokenId) external onlyOwner {

    // }

    // // Air drop bombs for all owners of Aviation of a specified level
    // function airdropBombs(uint level, uint bombCount) external onlyOwner {

    // }

    // // Mint L1s for all owners of Aviation of a specified level
    // function airdropL1s(uint level, uint l1Counts) external onlyOwner {

    // }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        
        string memory pilotString = "None";
        string memory baseUrl = _metadataBaseURI;
        address pilotAddress = _aviationPilotAddresses[tokenId];
        if (pilotAddress != address(0)) {
            pilotString = 
                string(abi.encodePacked(_pilotAddressesToNames[pilotAddress], " #", _aviationPilotIds[tokenId].toString()));
            baseUrl = string(abi.encodePacked(_pilotAddressesToUrls[pilotAddress], _aviationPilotIds[tokenId].toString(), "/"));
        }

        return _skylabMetadata.generateTokenMetadata(
            tokenId.toString(), 
            string(abi.encodePacked(baseUrl, _aviationLevels[tokenId].toString(), ".svg")),
            _aviationLevels[tokenId].toString(),
            _aviationPoints[tokenId].toString(),
            pilotString
        );
    }
}
