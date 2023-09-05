// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import {SkylabMetadata} from "./SkylabMetadata.sol";
import {SkylabResources} from "./SkylabResources.sol";

contract SkylabBase is ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 constant _maxLevel = 16;

    // per token data
    mapping(uint256 => uint256) public aviationLevels;
    mapping(uint256 => uint256) public aviationPoints;
    mapping(uint256 => bool) public aviationTradeLock;
    mapping(uint256 => uint256) public aviationPilotIds;
    mapping(uint256 => address) public aviationPilotAddresses;

    bool internal mintable;
    string internal _metadataBaseURI;
    mapping(address => mapping(uint256 => uint256)) internal _pilotToToken;

    // addresses
    SkylabResources internal _skylabResources;
    SkylabMetadata internal _skylabMetadata;
    mapping(address => bool) internal _gameAddresses;
    mapping(address => string) internal _pilotAddressesToNames;
    mapping(address => string) internal _pilotAddressesToUrls;

    event UpdateLevels(uint256 tokenID);

    modifier onlyGameAddresses() {
        require(_gameAddresses[_msgSender()], "SkylabBase: msg.sender is not a valid game address");
        _;
    }

    modifier onlyMintable() {
        require(mintable, "Mint not open");
        _;
    }

    constructor(string memory baseURI, string memory name, string memory symbol) ERC721(name, symbol) {
        _metadataBaseURI = baseURI;
    }

    // ====================
    // Mint
    // ====================

    function mint(address to) external onlyMintable {
        uint256 tokenID = super.totalSupply() + 1;
        _safeMint(to, tokenID);
        aviationLevels[tokenID] = 1;
    }
    // function addPilot(uint tokenId, uint pilotId, address pilotAddress) external {
    //     address pilotOwner = ERC721(pilotAddress).ownerOf(pilotId);
    //     require(_msgSender() == pilotOwner || ERC721(pilotAddress).isApprovedForAll(pilotOwner, _msgSender()) || ERC721(pilotAddress).getApproved(pilotId) == _msgSender(), "SkylabBase: pilot not owned by msg sender");
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
    //     require(_pilotAddressesToNames[pilotAddress] != "", "SkylabBase: unregistered pilotAddress");
    //     require(_pilotToToken[pilotAddress][pilotId] == 0, "SkylabBase: pilot already added");
    //     aviationPilotIds[tokenId] = pilotId;
    //     aviationPilotAddresses[tokenId] = pilotAddress;
    //     _pilotToToken[pilotAddress][pilotId] = tokenId;
    // }

    // ====================
    // Aviation level
    // ====================
    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) external onlyGameAddresses {
        require(_exists(winnerTokenId), "SkylabBase: nonexistent token");
        require(_exists(loserTokenId), "SkylabBase: nonexistent token");

        uint256 pointsToMove = aviationPoints[winnerTokenId] >= (uint256(aviationPoints[loserTokenId] + 1) / uint256(2))
            ? (uint256(aviationPoints[loserTokenId] + 1) / uint256(2))
            : aviationPoints[winnerTokenId];
        aviationPoints[winnerTokenId] += pointsToMove;
        if (pointsToMove >= aviationPoints[loserTokenId]) {
            aviationPoints[loserTokenId] = 0;
        } else {
            aviationPoints[loserTokenId] -= pointsToMove;
        }

        updateLevel(winnerTokenId);
        updateLevel(loserTokenId);

        if (aviationPoints[loserTokenId] == 0) {
            burnAviation(loserTokenId);
        }
    }

    function updateLevel(uint256 tokenId) private {
        for (uint256 i = 0; i <= _maxLevel; i++) {
            if (2 ** i > aviationPoints[tokenId]) {
                aviationLevels[tokenId] = i;
                emit UpdateLevels(tokenId);
                return;
            }
        }
        aviationLevels[tokenId] = _maxLevel;
        emit UpdateLevels(tokenId);
    }

    function burnAviation(uint256 tokenId) private {
        _burn(tokenId);
        _pilotToToken[aviationPilotAddresses[tokenId]][aviationPilotIds[tokenId]] = 0;
    }

    // ====================
    // MISC
    // ====================
    function requestResourcesForGame(address from, address game, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyGameAddresses
    {
        _skylabResources.burn(from, ids, amounts);
        _skylabResources.mintBatch(game, ids, amounts, "");
    }

    function refundResourcesFromGame(address game, address to, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyGameAddresses
    {
        _skylabResources.burn(game, ids, amounts);
        _skylabResources.mintBatch(to, ids, amounts, "");
    }

    function aviationLock(uint256 tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(!aviationTradeLock[tokenId], "SkylabBase: aviation locked");
        aviationTradeLock[tokenId] = true;
    }

    function aviationUnlock(uint256 tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        require(aviationTradeLock[tokenId], "SkylabBase: aviation not locked");
        aviationTradeLock[tokenId] = false;
    }

    function isAviationLocked(uint256 tokenId) external view virtual onlyGameAddresses returns (bool) {
        require(_exists(tokenId), "SkylabBase: nonexistent token");
        return aviationTradeLock[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!aviationTradeLock[tokenId], "SkylabBase: token is locked");
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
    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

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

    function registerPilotAddress(address pilotAddress, string memory pilotCollectionName, string memory baseUrl)
        external
        onlyOwner
    {
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
        address pilotAddress = aviationPilotAddresses[tokenId];
        if (pilotAddress != address(0)) {
            pilotString = string(
                abi.encodePacked(_pilotAddressesToNames[pilotAddress], " #", aviationPilotIds[tokenId].toString())
            );
            baseUrl =
                string(abi.encodePacked(_pilotAddressesToUrls[pilotAddress], aviationPilotIds[tokenId].toString(), "/"));
        }

        return _skylabMetadata.generateTokenMetadata(
            tokenId.toString(),
            string(abi.encodePacked(baseUrl, aviationLevels[tokenId].toString(), ".png")),
            aviationLevels[tokenId].toString(),
            aviationPoints[tokenId].toString(),
            pilotString
        );
    }
}
