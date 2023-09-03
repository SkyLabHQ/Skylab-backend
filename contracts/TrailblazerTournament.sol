// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { SkylabBase } from "./SkylabBase.sol";

contract TrailblazerTournament is SkylabBase {
    using Strings for uint;

    // tournament variables
    uint public _currentRound = 0;
    mapping(uint => uint) public _lastIndexPerRound;
    mapping(uint => uint) public _aviationRounds;

    struct LeaderboardInfo {
        uint tokenId;
        uint level;
    }

    constructor(string memory baseURI) SkylabBase(baseURI, "TrailblazerTournament", "TRAILBLAZER_TOURNAMENT") {
        _lastIndexPerRound[0] = 0;
    }

    function tournamentMint(address[] memory to, uint fuel, uint battery) external onlyOwner {
        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint[] memory resourceAmounts = new uint[](2);
        resourceAmounts[0] = fuel;
        resourceAmounts[1] = battery;
        for (uint i = 0; i < to.length; i++) {
            _safeMint(to[i], _nextTokenID);
            _aviationLevels[_nextTokenID] = 1;
            _aviationPoints[_nextTokenID] = 1;
            _aviationRounds[_nextTokenID] =  _currentRound;
            _nextTokenID++;
            _skylabResources.playTestNuke(to[i], ids);
            _skylabResources.mintBatch(to[i], ids, resourceAmounts, "");
        }
    }

    function tournamentRoundOver() external onlyOwner{
        _lastIndexPerRound[_currentRound] = _nextTokenID - 1;
        _currentRound++;
    }

    function leaderboardInfo(uint round) external view returns (LeaderboardInfo[] memory) {
        uint startIndex = _lastIndexPerRound[round - 1] + 1;
        uint endIndex = _lastIndexPerRound[round];
        LeaderboardInfo[] memory leaderboardInfos = new LeaderboardInfo[](endIndex - startIndex + 1);

        uint index = 0;
        for (uint i = startIndex; i <= endIndex; i++) {
            index = i - startIndex;
            leaderboardInfos[index] = LeaderboardInfo(i, _aviationLevels[i]);
        }
        return leaderboardInfos;
    }

    function isAviationLocked(uint tokenId) override external view onlyGameAddresses returns (bool) {
        require(_exists(tokenId), "SkylabTournament: nonexistent token");
        return _aviationRounds[tokenId] != _currentRound || _aviationTradeLock[tokenId];
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

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        return _skylabMetadata.generateTokenMetadata(
            tokenId.toString(), 
            string(abi.encodePacked(_metadataBaseURI, "Round", _aviationRounds[tokenId].toString(), "/", _aviationLevels[tokenId].toString(), ".png")),
            _aviationLevels[tokenId].toString(),
            _aviationPoints[tokenId].toString(),
            "None"
        );
    }
}
