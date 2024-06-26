// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/token/ERC721/SolidStateERC721.sol";
import "@solidstate/interfaces/IERC721.sol";
import "@solidstate/token/ERC721/base/ERC721BaseInternal.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract TrailblazerTournament is MercuryBase {
    using Strings for uint256;

    // tournament variables
    uint256 public _currentRound = 0;
    mapping(uint256 => uint256) public lastIndexPerRound;
    mapping(uint256 => uint256) public aviationRounds;

    struct LeaderboardInfo {
        uint256 tokenId;
        uint256 level;
    }

    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "TrailblazerTournament", "TrailblazerTournament", protocol);
        lastIndexPerRound[0] = 0;
    }

    /*//////////////////////////////////////////////////////////////
                            Mint Function
    //////////////////////////////////////////////////////////////*/

    function tournamentMint(address[] memory to) external {
        LibDiamond.enforceIsContractOwner();
        for (uint256 i = 0; i < to.length; i++) {
            uint256 tokenId = baseMint(to[i]);
            aviationRounds[tokenId] = _currentRound;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/

    function tournamentRoundOver() external {
        LibDiamond.enforceIsContractOwner();
        _tournamentRoundOver();
    }

    function _tournamentRoundOver() internal {
        lastIndexPerRound[_currentRound] = LibBase.layout().lastTokenID;
        _currentRound++;
    }

    /*//////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/

    function leaderboardInfo(uint256 round) public view returns (LeaderboardInfo[] memory) {
        uint256 startIndex = lastIndexPerRound[round - 1] + 1;
        uint256 endIndex;
        if (_currentRound != round) {
            endIndex = lastIndexPerRound[round];
        } else {
            endIndex = LibBase.layout().lastTokenID;
        }
        LeaderboardInfo[] memory leaderboardInfos = new LeaderboardInfo[](endIndex - startIndex + 1);

        uint256 index = 0;
        for (uint256 i = startIndex; i <= endIndex; i++) {
            index = i - startIndex;
            leaderboardInfos[index] = LeaderboardInfo(i, LibBase.layout().aviationLevels[i]);
        }
        return leaderboardInfos;
    }

    function isAviationLocked(uint256 tokenId) public view override returns (bool) {
        require(_exists(tokenId), "MercuryTournament: nonexistent token");
        return aviationRounds[tokenId] != _currentRound || LibBase.layout().aviationTradeLock[tokenId];
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        return LibBase.generateTokenMetadata(
            tokenId,
            string(
                abi.encodePacked(
                    "Round", aviationRounds[tokenId].toString(), "/", sbs.aviationLevels[tokenId].toString(), ".png"
                )
            )
        );
    }
}
