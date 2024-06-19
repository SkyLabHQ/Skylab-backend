// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../aviation/base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibVault} from "./storage/LibVault.sol";
import {Mercs} from "../campaign/Mercs.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4);
}

contract Vault is IERC721Receiver {
    Mercs public mercs;
    address public commissionReceiver;

    function initVault(MercuryBase _aviation) public {
        LibDiamond.enforceIsContractOwner();
        LibVault.layout().aviation = _aviation;
    }

    function setMercs(Mercs _mercs) public {
        LibDiamond.enforceIsContractOwner();
        mercs = _mercs;
    }

    function setCommissionReceiver(address _commissionReceiver) public {
        LibDiamond.enforceIsContractOwner();
        commissionReceiver = _commissionReceiver;
    }

    function BuyBack(uint256 tokenId, uint256 mercsTokenId) external payable {
        require(
            msg.sender == LibVault.aviation().ownerOf(tokenId) && !mercs.nonBuyBack(mercsTokenId),
            "Vault: msg.sender is not owner of token"
        );
        uint256 commissionPct = getCommmissionPct(LibVault.aviation().aviationLevels(tokenId));
        uint256 commission = price(tokenId) * commissionPct / 1e4;
        require(address(this).balance >= price(tokenId) - commission, "insufficient balance");
        payable(msg.sender).transfer(price(tokenId) - commission);
        payable(commissionReceiver).transfer(commission);
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
        return point * 1e16;
    }

    function getCommmissionPct(uint256 level) public pure returns (uint256) {
        require(level > 0, "Vault: level must be greater than 0");
        return (level - 1) * 100 + 400 >= 1000 ? 1000 : (level - 1) * 100 + 400;
    }

    receive() external payable {}
}
