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
        baseMint(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            Game Functions
    //////////////////////////////////////////////////////////////*/

    // function aviationLock(uint256 tokenId) external override onlyGameAddresses {}

    // function aviationUnlock(uint256 tokenId) external override onlyGameAddresses {}

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) public override onlyGameAddresses {}

    /*//////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/

    // function isAviationLocked(uint256) public pure override returns (bool) {
    //     return false;
    // }
}
