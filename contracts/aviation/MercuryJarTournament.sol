// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";

contract MercuryJarTournament is MercuryBase {
    uint256 public pot;
    mapping(uint256 => uint256) public levelToClaimTime;
    mapping(uint256 => uint256) public levelToNewComerId;
    mapping(uint256 => mapping(uint256 => string)) public userName;
    uint256 public nextTokenId;

    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryJarTournament", "MercuryJarTournament", protocol);
    }

    function mint() public payable {
        require(msg.value >= 0.01 ether, "");
        _safeMint(msg.sender, nextTokenId);
        addNewComer(nextTokenId, 1);
        nextTokenId++;
        pot += 0.01 ether;
    }

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) public override onlyGameAddresses {
        uint256 levelBefore = aviationLevels(winnerTokenId);
        super.aviationMovePoints(winnerTokenId, loserTokenId);
        uint256 levelAfter = aviationLevels(winnerTokenId);
        if (levelBefore < levelAfter) {
            addNewComer(winnerTokenId, levelAfter);
        }
    }

    function claimPot(uint256 tokenId) public {
        require(_ownerOf(tokenId) == msg.sender, "");
        uint256 level = aviationLevels(tokenId);
        require(levelToNewComerId[level] == tokenId, "");
        require(block.timestamp >= levelToClaimTime[level], "");
        // Reset the timer
        addNewComer(tokenId, level);

        payable(msg.sender).transfer(pot);
        pot = 0;
    }

    function addNewComer(uint256 tokenId, uint256 level) private {
        levelToClaimTime[level] = block.timestamp + 15 minutes * 2 ^ (level - 1);
        levelToNewComerId[level] = tokenId;
    }
}
