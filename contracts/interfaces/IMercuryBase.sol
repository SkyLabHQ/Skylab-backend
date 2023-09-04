// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMercuryBase {
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event UpdateLevels(uint256 tokenID);

    function approve(address to, uint256 tokenId) external;
    function aviationLevels(uint256 _tokenId) external view returns (uint256);
    function aviationLock(uint256 tokenId) external;
    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) external;
    function aviationPilotAddresses(uint256 _tokenId) external view returns (address);
    function aviationPilotIds(uint256 _tokenId) external view returns (uint256);
    function aviationPoints(uint256 _tokenId) external view returns (uint256);
    function aviationTradeLock(uint256 _tokenId) external view returns (bool);
    function aviationUnlock(uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
    function isAviationLocked(uint256 tokenId) external view returns (bool);
    function mercuryMetadata() external view returns (address);
    function mercuryResources() external view returns (address);
    function metadataBaseURI() external view returns (string memory);
    function mint(address to) external;
    function mintable() external view returns (bool);
    function name() external view returns (string memory);
    function ownerOf(uint256 tokenId) external view returns (address);
    function pilotAddressesToNames(address _pilotAddress) external view returns (string memory);
    function pilotAddressesToUrls(address _pilotAddress) external view returns (string memory);
    function pilotToToken(address _pilotAddress, uint256 _pilotId) external view returns (uint256);
    function refundResourcesFromGame(address game, address to, uint256[] memory ids, uint256[] memory amounts)
        external;
    function registerMetadataAddress(address metadataAddress) external;
    function registerMetadataURI(string memory metadataURI) external;
    function registerPilotAddress(address pilotAddress, string memory pilotCollectionName, string memory baseUrl)
        external;
    function registerResourcesAddress(address resourcesAddress) external;
    function requestResourcesForGame(address from, address game, uint256[] memory ids, uint256[] memory amounts)
        external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setMintable(bool _mintable) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
