// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {SkylabBase} from "./SkylabBase.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract Vault is Ownable, IERC721Receiver {
    SkylabBase skylabBaseNFT;

    constructor(SkylabBase _skylabBaseNFT) {
        skylabBaseNFT = _skylabBaseNFT;
    }

    function BuyBack(uint256 tokenId) external payable {
        require(address(this).balance >= price(tokenId), "insufficient balance");
        require(msg.sender == skylabBaseNFT.ownerOf(tokenId), "Vault: msg.sender is not owner of token");
        payable(msg.sender).transfer(price(tokenId));
        skylabBaseNFT.transferFrom(msg.sender, address(this), tokenId);
    }

    function sendNFT(uint256 tokenId, address to) external onlyOwner {
        skylabBaseNFT.transferFrom(address(this), to, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    function withdraw(uint256 value) external onlyOwner {
        payable(msg.sender).transfer(value);
    }

    function price(uint256 tokenId) public view returns (uint256) {
        uint256 point = skylabBaseNFT.aviationPoints(tokenId);
        return point / 3 * 1e18;
    }
}
