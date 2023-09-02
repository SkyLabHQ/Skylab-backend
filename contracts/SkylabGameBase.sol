// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import { SkylabBase } from "./SkylabBase.sol";


contract SkylabGameBase is Ownable, ERC1155Holder {
    using Strings for uint;

    SkylabBase internal _skylabBase;

    // token id => address
    mapping(uint256 => address) private _gameApprovals;


    constructor(address skylabBaseAddress) {
        _skylabBase = SkylabBase(skylabBaseAddress);
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
    }

    function unapproveForGame(uint tokenId) public virtual {
    	require(isApprovedForGame(tokenId), "SkylabGameBase: caller is not token owner or approved");
    	delete _gameApprovals[tokenId];
    }

    // =====================
    // Utils
    // ===================== 
    function registerSkylabBase(address skylabBaseAddress) external onlyOwner {
        _skylabBase = SkylabBase(skylabBaseAddress);
    }
}
