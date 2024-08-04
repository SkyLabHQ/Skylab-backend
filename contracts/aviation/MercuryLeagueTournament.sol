// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryJarTournament is MercuryBase {
    uint256 constant leagueOwner = 20;
    uint256 constant newComer = 80;

    uint256 public pot;
    address public admin;

    struct LeagueInfo {
        uint256[] tokenIds;
        bool isLeagueLocked;
        bool leaderExist;
    }
    mapping(uint256 => uint256) public levelToClaimTime;
    mapping(uint256 => uint256) public levelToNewComerId;
    mapping(uint256 => uint256[]) public tokenIdPerLevel;
    mapping(address leader => LeagueInfo) public league;
    mapping(address member => address leader) memberToLeader;
    modifier onlyAdmin {
        require(msg.sender == admin, "Permission deny");
        _;
    }
    
    function initialize(string memory baseURI, address protocol) public {
        super.initialize(baseURI, "MercuryJarTournament", "MercuryJarTournament", protocol);
    }

    function mint(uint256 amount) public payable returns(uint256[] memory) {
        require(msg.value == 0.02 ether * amount, "MercuryJarTournament:  not enough ether to mint");
        uint256[] memory res = new uint256[](amount);
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = baseMint(msg.sender);
            res[i] = tokenId;
            addNewComer(tokenId, 1);
        }
        pot += msg.value;
        return res;
    }

    function joinLeague(address leader) public {
        require(league[leader].leaderExist, "leader not exist");
        require(!league[leader].isLeagueLocked, "MercuryJarTournament: leagueLocked");
        uint256[] memory tokenIds = mint(1);
        uint256 tokenId = tokenIds[0];
        league[leader].tokenIds.push(tokenId);
        memberToLeader[msg.sender] = leader;
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
        payable(msg.sender).transfer(pot*newComer/100);
        payable(leader).transfer(pot*leagueOwner/100);
        pot = 0;
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
        uint256[] memory tokenIds = mint(1);
        uint256 tokenId = tokenIds[0];
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

}
