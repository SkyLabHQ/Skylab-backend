// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {LibGameBase} from "./storage/LibGameBase.sol";
import {ComponentIndex} from "../../protocol/ComponentIndex.sol";
import {IERC721} from "../../interfaces/IERC721.sol";

abstract contract MercuryGameBase is ERC1155Holder {
    using Strings for uint256;

    constructor(address _protocol) {
        LibGameBase.setContractOwner(msg.sender);
        LibGameBase.layout().protocol = _protocol;
    }

    modifier onlyOwner() {
        require(LibGameBase.contractOwner() == msg.sender, "MercuryGameBase: caller is not the owner");
        _;
    }

    function baseCreateLobby(address newGame) internal {
        LibGameBase.baseCreateLobby(newGame);
    }

    function baseJoinLobby(address lobby) internal {
        LibGameBase.baseJoinLobby(lobby);
    }

    // =====================
    // Approval
    // =====================
    function isApprovedForGame(uint256 tokenId, MercuryBase collection) public view virtual returns (bool) {
        return collection.isApprovedOrOwner(msg.sender, tokenId)
            || LibGameBase.gameApprovals(tokenId) == msg.sender;
    }

    function approveForGame(address burner, uint256 tokenId, MercuryBase collection) public virtual {
        require(isApprovedForGame(tokenId, collection), "MercuryGameBase: caller is not token owner or approved");
        require(!collection.isAviationLocked(tokenId), "MercuryGameBase: token has been locked");
        LibGameBase.layout().gameApprovals[tokenId] = burner;
        LibGameBase.layout().burnerAddressToTokenId[burner] = tokenId;
    }

    function unapproveForGame(uint256 tokenId, MercuryBase collection) public virtual {
        require(isApprovedForGame(tokenId, collection), "MercuryGameBase: caller is not token owner or approved");
        require(!collection.isAviationLocked(tokenId), "MercuryGameBase: token has been locked");
        delete  LibGameBase.layout().gameApprovals[tokenId];
        delete LibGameBase.layout().burnerAddressToTokenId[msg.sender];
    }

    // =====================
    // Utils
    // =====================

    function transferOwnership(address _newOwner) external {
        LibGameBase.enforceIsContractOwner();
        LibGameBase.setContractOwner(_newOwner);
    }

    function owner() external view returns (address owner_) {
        owner_ = LibGameBase.contractOwner();
    }

    function componentIndex() public view returns (ComponentIndex) {
        return ComponentIndex(LibGameBase.protocol());
    }

    function burnerAddressToTokenId(address burner) public view returns (uint256) {
        return LibGameBase.burnerAddressToTokenId(burner);
    }
}
