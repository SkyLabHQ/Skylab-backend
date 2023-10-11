// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@solidstate/interfaces/IERC721.sol";
import "@solidstate/token/ERC721/base/ERC721Base.sol";
import "@solidstate/token/ERC721/base/ERC721BaseInternal.sol";
import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryTestFlight is MercuryBase {
    using Strings for uint256;

    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryTestFlight", "SKYLAB_TEST_FLIGHT", protocol);
    }

    /*//////////////////////////////////////////////////////////////
                            Mint Function
    //////////////////////////////////////////////////////////////*/

    function playTestMint() external {
        uint256 tokenId = LibBase.layout().nextTokenId + 1;
        LibBase.layout().nextTokenId++;
        _safeMint(msg.sender, tokenId);
        LibBase.layout().aviationTradeLock[tokenId] = true;
        LibBase.layout().aviationLevels[tokenId] = 1;
        LibBase.layout().aviationPoints[tokenId] = 1;
    }

    /*//////////////////////////////////////////////////////////////
                            Game Functions
    //////////////////////////////////////////////////////////////*/

    function aviationLock(uint256 tokenId) external override onlyGameAddresses {}

    function aviationUnlock(uint256 tokenId) external override onlyGameAddresses {}

    /*//////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/

    function isAviationLocked(uint256) public pure override returns (bool) {
        return false;
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override(ERC721Base, IERC721)
        returns (bool isOperator)
    {
        // If anything is trade locked, reject
        for (uint256 i = 0; i < ERC721BaseInternal._balanceOf(_owner); i++) {
            uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
            if (LibBase.layout().aviationTradeLock[tokenId]) {
                return false;
            }
        }

        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // PLAY TEST
        if (_operator == LibDiamond.contractOwner()) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721BaseInternal._isApprovedForAll(_owner, _operator);
    }
}
