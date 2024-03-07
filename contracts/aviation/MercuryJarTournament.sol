// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract MercuryJarTournament is MercuryBase {
    mapping(uint256 => uint256) public levelToClaimTime;
    mapping(uint256 => uint256) public levelToNewComerId;
    mapping(address => string) public userName;
    mapping(uint256 => string[]) public userNamePerLevel;
    mapping(string => bool) public userNameUsed;
    mapping(address => uint256) public paperBalance;
    
    uint256 public pot;
    uint256 public nextTokenId;
    bool isTournamentBegin;

    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryJarTournament", "MercuryJarTournament", protocol);
    }

    function mintPaper(uint256 amount) public payable {
        require(!isTournamentBegin, "MercuryJarTournament: tournament already begin");
        require(msg.value >= 0.01 ether * amount, "MercuryJarTournament: not enough ether to mint");
        paperBalance[msg.sender] += amount;
        pot += msg.value;
    }

    function mint(uint256 amount) public payable {
        require(isTournamentBegin, "MercuryJarTournament: tournament not begin");
        require(msg.value >= 0.02 ether * amount, "MercuryJarTournament:  not enough ether to mint");
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, nextTokenId);
            addNewComer(nextTokenId, 1);
            nextTokenId++;
        }
        pot += msg.value;
    }

    function mintWithPaper(uint256 amount ) public {
        require(isTournamentBegin, "MercuryJarTournament: tournament not begin");
        require(paperBalance[msg.sender] > amount,"MercuryJarTournament: no voucher to mint");
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, nextTokenId);
            addNewComer(nextTokenId, 1);
            nextTokenId++;
            paperBalance[msg.sender] -= 1;
        }
    }

    function setTournamentBegin(bool _isTournamentBegin) public {
        LibDiamond.enforceIsContractOwner();
        isTournamentBegin = _isTournamentBegin;
    }

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) public override onlyGameAddresses {
        uint256 levelBefore = aviationLevels(winnerTokenId);
        super.aviationMovePoints(winnerTokenId, loserTokenId);
        uint256 levelAfter = aviationLevels(winnerTokenId);
        if (levelBefore < levelAfter) {
            addNewComer(winnerTokenId, levelAfter);
            if (bytes(userName[msg.sender]).length > 0) {
                for (uint256 i = 0; i < userNamePerLevel[levelBefore].length; i++) {
                    if (keccak256(bytes(userNamePerLevel[levelBefore][i])) == keccak256(bytes(userName[msg.sender]))) {
                        userNamePerLevel[levelBefore][i] =
                            userNamePerLevel[levelBefore][userNamePerLevel[levelBefore].length - 1];
                        userNamePerLevel[levelBefore].pop();
                        break;
                    }
                }
            }
        }
    }

    function estimatePointsToMove(uint256 winnerTokenId, uint256 loserTokenId) public view override returns (uint256) {
        if (winnerTokenId == 0 || loserTokenId == 0) {
            return 1;
        } else {
            return super.estimatePointsToMove(winnerTokenId, loserTokenId);
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
        string memory username = userName[msg.sender];
        if (bytes(username).length > 0) {
            userNamePerLevel[level].push(username);
        }
    }

    function registerUserName(string memory _username) public {
        require(bytes(_username).length > 0, "MercuryJarTournament: user name too short");
        require(!userNameUsed[_username], "MercuryJarTournament: user name used");
        require(bytes(userName[msg.sender]).length == 0, "MercuryJarTournament: user name already registered");
        userName[msg.sender] = _username;
    }

    function planeToUserName(uint256 tokenId) public view returns (string memory) {
        return userName[_ownerOf(tokenId)];
    }

    function getUserNamePerLevel(uint256 level) public view returns (string[] memory) {
        return userNamePerLevel[level];
    }
}
