// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryLeagueTournament is MercuryBase {
    struct LeagueInfo {
        uint256[] tokenIds;
        bool isLeagueLocked;
        bool leaderExist;
        uint256 leagueOwnerPercentage;
        uint256 newComerPercentage;
    }

    uint256 public pot;
    address public admin;
    uint256 public paperTotalAmount;
    mapping(address => uint256) public paperBalance;
    mapping(uint256 => uint256) public levelToClaimTime;
    mapping(uint256 => uint256) public levelToNewComerId;
    mapping(uint256 => uint256[]) public tokenIdPerLevel;
    mapping(address leader => LeagueInfo) public league;
    mapping(address member => address leader) memberToLeader;
    
    modifier onlyAdmin {
        require(msg.sender == admin, "MercuryLeagueTournament: Permission deny");
        _;
    }
    
    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryLeagueTournament", "MercuryLeagueTournament", protocol);
    }

    function mintPaper(uint256 amount) public payable {
        require(msg.value == 0.01 ether * amount, "MercuryLeagueTournament: not enough ether to mint");
        paperBalance[msg.sender] += amount;
        pot += msg.value;
        paperTotalAmount += amount;
    }

    function mintWithPaper(address leader) public {
        require(paperBalance[msg.sender] >= 1, "MercuryLeagueTournament: no voucher to mint");
        uint256 tokenId = baseMint(msg.sender);
        addNewComer(tokenId, 1);
        paperBalance[msg.sender] -= 1;
        paperTotalAmount -= 1;
        joinLeague(tokenId, leader);
    }

    function mint(address leader) public payable {
        require(msg.value == 0.02 ether, "MercuryLeagueTournament:  not enough ether to mint");
        uint256 tokenId = baseMint(msg.sender);
        addNewComer(tokenId, 1);
        pot += msg.value;
        joinLeague(tokenId, leader);
    }

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) public override onlyAdmin {
        uint256 winnerLevelBefore = aviationLevels(winnerTokenId);
        uint256 loserLevelBefore = aviationLevels(loserTokenId);
        if (winnerTokenId != 0 && loserTokenId != 0) {
            super.aviationMovePoints(winnerTokenId, loserTokenId);
        } else {
            aviationBotMovePoints(winnerTokenId, loserTokenId);
        }
        uint256 winnerLevelAfter = aviationLevels(winnerTokenId);
        uint256 loserLevelAfter = aviationLevels(loserTokenId);
        if (loserLevelBefore > loserLevelAfter) {
            tokenIdPerLevelMove(loserTokenId, loserLevelBefore);
        }

        if (winnerLevelBefore < winnerLevelAfter) {
            addNewComer(winnerTokenId, winnerLevelAfter);
            tokenIdPerLevelMove(winnerTokenId, winnerLevelBefore);
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
        address vault = LibBase.layout().protocol;
        address leader = memberToLeader[msg.sender];
        payable(vault).transfer(pot/100);
        payable(msg.sender).transfer(pot*league[leader].newComerPercentage/100);
        payable(leader).transfer(pot*league[leader].leagueOwnerPercentage/100);
        uint256 valueAfter = pot - (pot/100 + (pot*league[leader].newComerPercentage/100) + pot*league[leader].leagueOwnerPercentage/100);
        uint256 totalPoints;
        for(uint i = 0; i < league[leader].tokenIds.length; i++) {
            uint256 tokenId_ = league[leader].tokenIds[i];
            totalPoints += aviationPoints(tokenId_);
        }
        for(uint i = 0; i < league[leader].tokenIds.length; i++) {
            uint256 tokenId_ = league[leader].tokenIds[i];
            address receiver = _ownerOf(tokenId_);
            uint256 points = aviationPoints(tokenId_);
            payable(receiver).transfer(valueAfter * points / totalPoints);
        }
        pot = 0;
    }

    function setPercentage(uint256 _newComerPercentage, uint256 _leagueOwnerPercentage) public {
        require(league[msg.sender].leaderExist, "MercuryLeagueTournament: Permission deny");
        require(_newComerPercentage <= 20 && _leagueOwnerPercentage <= 20, "MercuryLeagueTournament: all argument should be less than or equal to 20");
        for (uint i = 0; i < league[msg.sender].tokenIds.length; i++) {
            uint256 tokenId = league[msg.sender].tokenIds[i];
            uint256 level = aviationLevels(tokenId);
            require(levelToClaimTime[level] > block.timestamp && levelToClaimTime[level] - block.timestamp >= 5 minutes, "MercuryLeagueTournament: pass setPercentage time lock");
        }
        league[msg.sender].leagueOwnerPercentage = _leagueOwnerPercentage;
        league[msg.sender].newComerPercentage = _newComerPercentage;
    }


    function getTokenIdPerLevel(uint256 level) public view returns (uint256[] memory) {
        return tokenIdPerLevel[level];
    }

    function setAdmin(address _admin) public {
        LibDiamond.enforceIsContractOwner();
        admin = _admin;
    }

    function setLeagueLockStatus(bool isLocked) public {
        require(league[msg.sender].leaderExist, "Leader not exist");
        league[msg.sender].isLeagueLocked = isLocked;
    }

    function setLeader(address _leader) public onlyAdmin {
        uint256 tokenId = baseMint(msg.sender);
        addNewComer(tokenId, 1);
        league[_leader].tokenIds.push(tokenId);
        league[_leader].leaderExist = true;
    }

    function getNewCommerInfo(uint256 level)
        public
        view
        returns (uint256 claimTime, uint256 newComerId, address owner, uint256 point)
    {
        claimTime = levelToClaimTime[level];
        newComerId = levelToNewComerId[level];
        if (_exists(newComerId)) {
            owner = _ownerOf(newComerId);
        } else {
            owner = address(0);
        }
        point = aviationPoints(newComerId);
    }

    // Private Function

    function aviationBotMovePoints(uint256 winnerTokenId, uint256 loserTokenId) private {
        bool playerWon = loserTokenId == 0;
        uint256 playerTokenId = winnerTokenId + loserTokenId;

        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        uint256 pointsToMove = 1;

        if (playerWon) {
            sbs.aviationPoints[playerTokenId] += pointsToMove;
            emit LibBase.MovePoints(0, playerTokenId, pointsToMove);
        } else {
            sbs.aviationPoints[playerTokenId] -= pointsToMove;
            emit LibBase.MovePoints(playerTokenId, 0, pointsToMove);
        }
        LibBase.loyaltyPoints().playGame(_ownerOf(playerTokenId), pointsToMove);
        updateLevel(playerTokenId);

        if (sbs.aviationPoints[playerTokenId] == 0) {
            burnAviation(playerTokenId);
        }
    }

    function tokenIdPerLevelMove(uint256 tokenId, uint256 levelBefore) internal {
        if (levelToNewComerId[levelBefore] == tokenId) {
            levelToNewComerId[levelBefore] = 0;
            levelToClaimTime[levelBefore] = 0;
        }
        for (uint256 i = 0; i < tokenIdPerLevel[levelBefore].length; i++) {
            if (tokenIdPerLevel[levelBefore][i] == tokenId) {
                tokenIdPerLevel[levelBefore][i] = tokenIdPerLevel[levelBefore][tokenIdPerLevel[levelBefore].length - 1];
                tokenIdPerLevel[levelBefore].pop();
                break;
            }
        }
    }

    function joinLeague(uint256 tokenId, address leader) private {
        require(league[leader].leaderExist, "MercuryLeagueTournament: leader not exist");
        require(!league[leader].isLeagueLocked, "MercuryLeagueTournament: leagueLocked");
        require(memberToLeader[msg.sender] == address(0), "MercuryLeagueTournament: Already join league");
        league[leader].tokenIds.push(tokenId);
        memberToLeader[msg.sender] = leader;
    }
    
    function addNewComer(uint256 tokenId, uint256 level) private {
        if (block.timestamp >= levelToClaimTime[level]) {
            uint256 preTokenId = levelToNewComerId[level];
            if (_exists(preTokenId)) {
                address owner = _ownerOf(preTokenId);
                payable(owner).transfer(pot);
                pot = 0;
            }
        }
        levelToClaimTime[level] = block.timestamp + 15 minutes * 2 ^ (level - 1);
        levelToNewComerId[level] = tokenId;
        tokenIdPerLevel[level].push(tokenId);
    }

}
