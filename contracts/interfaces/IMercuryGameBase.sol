// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMercuryGameBase {
    function approveForGame(address to, uint256 tokenId) external;
    function isApprovedForGame(uint256 tokenId) external view returns (bool);
    function mercuryBase() external view returns (address);
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        external
        returns (bytes4);
    function onERC1155Received(address, address, uint256, uint256, bytes memory) external returns (bytes4);
    function registerMercuryBase(address mercuryBaseAddress) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function unapproveForGame(uint256 tokenId) external;
}
