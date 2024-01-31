// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";

contract MercuryJarTournament is MercuryBase {
    mapping(uint256 => uint256) public levelToCoolDownTime;
    mapping(uint256 => uint256) public levelToPod;
    mapping(uint256 => address) public levelToNewComer;
    mapping(uint256 => mapping(uint256 => string)) public userName;
    uint256 public nextTokenId;

    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryJarTournament", "MercuryJarTournament", protocol);
    }

    function mint() public payable {
        uint256 level = 1;
        require(block.timestamp <= levelToCoolDownTime[level], "");
        require(msg.value == 0.01 ether, "");
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
        levelToCoolDownTime[level] = 15 minutes;
        levelToNewComer[level] = msg.sender;
        levelToPod[level] += 0.01 ether;
    }

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) public override onlyGameAddresses {
        uint256 levelBefore = aviationLevels(winnerTokenId);
        super.aviationMovePoints(winnerTokenId, loserTokenId);
        uint256 levelAfter = aviationLevels(winnerTokenId);
        if (levelBefore != levelAfter) {
            
        }
    }


    function claimJar(uint256 tokenId) public {
        require(_ownerOf(tokenId) == msg.sender, "");
        uint256 level = aviationLevels(tokenId);
        require(levelToNewComer[level] == msg.sender, "");
        require(block.timestamp > levelToCoolDownTime[level], "");
        levelToCoolDownTime[level] = 0;
        levelToNewComer[level] = address(0);
        uint256 pod = levelToPod[level];
        levelToPod[level] = 0;
        payable(msg.sender).transfer(pod);
    }

}