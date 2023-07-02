// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SkylabBase } from "./SkylabBase.sol";

contract SkylabTestFlight is SkylabBase {
    using Strings for uint;

    constructor(string memory baseURI) SkylabBase(baseURI, "SkylabTestFlight", "SKYLAB_TEST_FLIGHT") {}

    function playTestMint() external {
        _safeMint(_msgSender(), _nextTokenID);
        _aviationTradeLock[_nextTokenID] = true;
        _aviationLevels[_nextTokenID] = 1;
        _nextTokenID++;
        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint[] memory resourceAmounts = new uint[](2);
        resourceAmounts[0] = 25000;
        resourceAmounts[1] = 25000;
        _skylabResources.playTestNuke(_msgSender(), ids);
        _skylabResources.mintBatch(_msgSender(), ids, resourceAmounts, "");
    }

    function aviationLock(uint tokenId) override external onlyGameAddresses  {}

    function aviationUnlock(uint tokenId) override external onlyGameAddresses  {}

    function isAviationLocked(uint tokenId) override external view onlyGameAddresses returns (bool) {
        return false;
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) public override(ERC721, IERC721) view returns (bool isOperator) {
        // If anything is trade locked, reject
        for (uint256 i = 0; i < ERC721.balanceOf(_owner); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            if (_aviationTradeLock[tokenId]) {
                return false;
            }
        }

      // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // PLAY TEST
        if (_operator == owner()) {
            return true;
        }
        
        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }
}