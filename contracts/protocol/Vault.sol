// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../aviation/base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibVault} from "./storage/LibVault.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract Vault is IERC721Receiver {
    function initVault(MercuryBase _aviation) public {
        LibDiamond.enforceIsContractOwner();
        LibVault.layout().aviation = _aviation;
    }

    function BuyBack(uint256 tokenId) external payable {
        require(msg.sender == LibVault.aviation().ownerOf(tokenId), "Vault: msg.sender is not owner of token");
        uint256 commissionPct = getCommmission(LibVault.aviation().aviationLevels(tokenId));
        uint256 commision = price(tokenId) * commissionPct / 1e4;
        require(address(this).balance >= price(tokenId) - commision, "insufficient balance");
        payable(msg.sender).transfer(price(tokenId) - commision);
        LibVault.aviation().transferFrom(msg.sender, address(this), tokenId);
    }

    function sendNFT(uint256 tokenId, address to) external {
        LibDiamond.enforceIsContractOwner();
        LibVault.aviation().transferFrom(address(this), to, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdraw(uint256 value) external {
        LibDiamond.enforceIsContractOwner();
        payable(msg.sender).transfer(value);
    }

    function aviation() public view returns (MercuryBase) {
        return LibVault.layout().aviation;
    }

    function price(uint256 tokenId) public view returns (uint256) {
        uint256 point = LibVault.aviation().aviationPoints(tokenId);
        return point / 3 * 1e18;
    }

    function getCommmission(uint256 level) public pure returns (uint256) {
        require(level > 0 && level <= 10, "invalid level");
        for (uint256 i = 1; i <= 10; i++) {
            if (level == i) {
                return (i - level) * 200 + 400 >= 2000 ? 2000 : (i - level) * 200 + 400;
            }
        }
        return 0;
    }

    receive() external payable {}
}
