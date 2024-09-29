// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";
import {MercuryGameBase} from "../games/base/MercuryGameBase.sol";
import {Paper} from "../campaign/Paper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MercuryLeagueTournament is MercuryBase, ReentrancyGuard {
    struct LeagueInfo {
        bool isLocked;
        bool leaderExist;
        bool isWinner;
        uint256[] tokenIds;
        uint256 preLeagueOwnerPercentage;
        uint256 preNewComerPercentage;
        uint256 leagueOwnerPercentage;
        uint256 newComerPercentage;
        uint256 setPercentageTime;
        uint256 currentVetoPoint;
        uint256 totalVetoPoint;
        uint256 premium;
        address winnerNewComer;
        mapping(uint256 => uint256) tokenIdToVetoPoints;
        mapping(uint256 => bool) isClaimed;
    }

    bool public isPaused;
    uint256 public pot;
    address public admin;
    uint256 public paperTotalAmount;
    Paper public paper;

    mapping(address => uint256) public paperBalance;
    mapping(uint256 => uint256) public levelToClaimTime;
    mapping(uint256 => uint256) public levelToNewComerId;
    mapping(uint256 => uint256[]) public tokenIdPerLevel;
    mapping(address => address) public memberToLeader;
    mapping(address => LeagueInfo) public league; // leader to LeagueInfo
    mapping(bytes => bool) public signatureUsed;

    modifier onlyAdmin() {
        require(msg.sender == admin, "MercuryLeagueTournament: Permission deny");
        _;
    }

    modifier notPaused() {
        require(!isPaused, "MercuryLeagueTournament: Tournament pause");
        _;
    }

    modifier isPotClaimable() {
        for (uint256 level = 0; level < LibBase.MAXLEVEL; level++) {
            if (block.timestamp >= levelToClaimTime[level]) {
                uint256 preTokenId = levelToNewComerId[level];
                if (_exists(preTokenId)) {
                    address owner = _ownerOf(preTokenId);
                    finalizeWinner(owner);
                }
            }
        }
        _;
    }

    function initialize(string memory baseURI, address protocol, address _admin) public {
        super.initialize(baseURI, "MercuryLeagueTournament", "MercuryLeagueTournament", protocol);
        admin = _admin;
    }

    //==============================================================================================================================
    //=============================================USER FUNTION==================================================================
    //==============================================================================================================================

    function mintPaper(uint256 amount) public payable notPaused {
        require(msg.value == 0.01 ether * amount, "MercuryLeagueTournament: not enough ether to mint");
        paper.mint(msg.sender, amount);
        pot += msg.value;
    }

    function mintWithPaper(address leader) public payable {
        uint256 tokenId = baseMint(msg.sender);
        addNewComer(tokenId, 1);
        paper.burn(msg.sender, 1);
        joinLeague(tokenId, leader);
    }

    function mint(address leader, address referral, uint256 expirationTime, bytes calldata signature) public payable notPaused {
        if(referral != address(0)) {
            verifySignature(referral, expirationTime, signature);
        }
        require(msg.value == 0.02 ether + league[leader].premium, "MercuryLeagueTournament:  not enough ether to mint");
        uint256 tokenId = baseMint(msg.sender);
        addNewComer(tokenId, 1);
        pot += (msg.value - league[leader].premium);
        joinLeague(tokenId, leader);
        if (referral != address(0) && _balanceOf(referral) > 0) {
            payable(referral).transfer(league[leader].premium);
            return;
        }
        //distribute premium
        LeagueInfo storage leagueInfo = league[leader];
        uint256 totalPoints;
        for (uint256 i = 0; i < leagueInfo.tokenIds.length; i++) {
            uint256 _tokenId = leagueInfo.tokenIds[i];
            totalPoints += aviationPoints(_tokenId);
        }
        for (uint256 i = 0; i < leagueInfo.tokenIds.length; i++) {
            uint256 _tokenId = leagueInfo.tokenIds[i];
            uint256 points = aviationPoints(_tokenId);
            address owner = _ownerOf(_tokenId);
            payable(owner).transfer(league[leader].premium * points / totalPoints);
        }
    }

    function claimPot(address account) public returns(uint256) {
        uint256 balance = _balanceOf(account);
        uint256 totalValue;
        for(uint i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            uint256 value = claimPot(tokenId);
            totalValue += value;
        }
        return totalValue;
    }

    function claimPot(uint256 tokenId) public nonReentrant returns (uint256) {
        address owner = _ownerOf(tokenId);
        require(owner == msg.sender, "MercuryLeagueTournament: not owner");
        address leader = memberToLeader[owner];
        LeagueInfo storage leagueInfo = league[leader];
        require(!leagueInfo.isClaimed[tokenId], "MercuryLeagueTournament: has claimed");
        require(leagueInfo.isWinner, "MercuryLeagueTournament: not winner");
        address newComer = leagueInfo.winnerNewComer;
        for (uint256 i = 0; i < leagueInfo.tokenIds.length; i++) {
            uint256 tokenId_ = leagueInfo.tokenIds[i];
            if (tokenId == tokenId_) {
                uint256 totalPoints;
                for (uint256 j = 0; j < leagueInfo.tokenIds.length; j++) {
                    uint256 _tokenId = leagueInfo.tokenIds[j];
                    totalPoints += aviationPoints(_tokenId);
                }
                uint256 points = aviationPoints(tokenId_);
                uint256 ownerValue = pot * (100 - leagueInfo.newComerPercentage - leagueInfo.leagueOwnerPercentage)
                    * points / totalPoints / 100;
                payable(owner).transfer(ownerValue);
                pot = pot - ownerValue;
                leagueInfo.isClaimed[tokenId] = true;
                return ownerValue;
            }
        }
        if (msg.sender == newComer) {
            uint256 denominator = 100;
            uint256 newComerValue = pot * leagueInfo.newComerPercentage / denominator;
            payable(owner).transfer(newComerValue);
            pot = pot - newComerValue;
            leagueInfo.isClaimed[tokenId] = true;
            return newComerValue;
        }
        if (msg.sender == leader) {
            uint256 denominator = 100;
            uint256 leaderValue = pot * leagueInfo.leagueOwnerPercentage / denominator;
            payable(leader).transfer(leaderValue);
            pot = pot - leaderValue;
            leagueInfo.isClaimed[tokenId] = true;
            return leaderValue;
        }
        return 0;
    }

    function setPaper(Paper _paper) public {
        LibDiamond.enforceIsContractOwner();
        paper = _paper;
    }

    function setPercentage(uint256 _newComerPercentage, uint256 _leagueOwnerPercentage) public {
        LeagueInfo storage leagueInfo = league[msg.sender];
        require(leagueInfo.leaderExist, "MercuryLeagueTournament: Permission deny");
        require(
            _newComerPercentage <= 20 && _newComerPercentage >= 10 && _leagueOwnerPercentage <= 20,
            "MercuryLeagueTournament: Argument Error"
        );
        if (isTimeFrozen()) {
            require(
                !isDominatingLeague(msg.sender),
                "MercuryLeagueTournament: dominating league can't change when any timer is less than 10min"
            );
        }
        for (uint256 i = 0; i < leagueInfo.tokenIds.length; i++) {
            uint256 tokenId = leagueInfo.tokenIds[i];
            uint256 level = aviationLevels(tokenId);
            require(
                levelToClaimTime[level] > block.timestamp && levelToClaimTime[level] - block.timestamp >= 5 minutes,
                "MercuryLeagueTournament: pass setPercentage time lock"
            );
        }
        require(
            block.timestamp >= leagueInfo.setPercentageTime + 2 hours,
            "MercuryLeagueTournament: veto windows didn't expire"
        );
        leagueInfo.setPercentageTime = block.timestamp;
        leagueInfo.preLeagueOwnerPercentage = leagueInfo.leagueOwnerPercentage;
        leagueInfo.preNewComerPercentage = leagueInfo.newComerPercentage;
        leagueInfo.leagueOwnerPercentage = _leagueOwnerPercentage;
        leagueInfo.newComerPercentage = _newComerPercentage;
        leagueInfo.currentVetoPoint = 0;
        leagueInfo.totalVetoPoint = 0;
        for (uint256 i = 0; i < leagueInfo.tokenIds.length; i++) {
            uint256 tokenId = leagueInfo.tokenIds[i];
            leagueInfo.tokenIdToVetoPoints[tokenId] = aviationPoints(tokenId);
            leagueInfo.totalVetoPoint += aviationPoints(tokenId);
        }
    }

    function vetoLeaderDecision(uint256 tokenId) public {
        address leader = memberToLeader[msg.sender];
        require(
            league[leader].leaderExist && _ownerOf(tokenId) == msg.sender, "MercuryLeagueTournament: Permission deny"
        );
        require(
            block.timestamp <= league[leader].setPercentageTime + 1 hours,
            "MercuryLeagueTournament: veto windows expired"
        );
        uint256 points = league[leader].tokenIdToVetoPoints[tokenId];
        league[leader].currentVetoPoint += points;
        if (league[leader].currentVetoPoint * 2 > league[leader].totalVetoPoint) {
            league[leader].newComerPercentage = league[msg.sender].preLeagueOwnerPercentage;
            league[leader].leagueOwnerPercentage = league[msg.sender].preLeagueOwnerPercentage;
        }
    }

    function setLeagueLockStatus(bool isLocked) public {
        require(league[msg.sender].leaderExist, "Leader not exist");
        league[msg.sender].isLocked = isLocked;
    }

    function setPremium(uint256 premium) public {
        require(league[msg.sender].leaderExist, "Leader not exist");
        require(premium >= 5 * 10 ** 15, "premium must greater than 0.005 ether");
        require(premium > league[msg.sender].premium, "premium only be greater than previout premium");
        league[msg.sender].premium = premium;
    }
    //==============================================================================================================================
    //=============================================ADMIN FUNTION==================================================================
    //==============================================================================================================================

    function setAdmin(address _admin) public {
        LibDiamond.enforceIsContractOwner();
        admin = _admin;
    }

    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId)
        public
        override
        onlyGameAddresses
        notPaused
    {
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

    function setLeader(address _leader) public onlyAdmin {
        league[_leader].leaderExist = true;
        league[_leader].newComerPercentage = 10;
    }

    //==============================================================================================================================
    //=============================================VIEW FUNTION==================================================================
    //==============================================================================================================================

    function estimatePointsToMove(uint256 winnerTokenId, uint256 loserTokenId) public view override returns (uint256) {
        if (winnerTokenId == 0 || loserTokenId == 0) {
            return 1;
        } else {
            return super.estimatePointsToMove(winnerTokenId, loserTokenId);
        }
    }

    function getnewComerInfo(uint256 level)
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

    function getTokenIdPerLevel(uint256 level) public view returns (uint256[] memory) {
        return tokenIdPerLevel[level];
    }

    function getLeagueInfo(address leader) public view returns (
        bool isLocked,
        bool leaderExist,
        bool isWinner,
        uint256[] memory tokenIds,
        uint256 preLeagueOwnerPercentage,
        uint256 preNewComerPercentage,
        uint256 leagueOwnerPercentage,
        uint256 newComerPercentage,
        uint256 setPercentageTime,
        uint256 currentVetoPoint,
        uint256 totalVetoPoint,
        uint256 premium,
        address winnerNewComer
    ) {
        LeagueInfo storage info = league[leader];
        
        return (
            info.isLocked,
            info.leaderExist,
            info.isWinner,
            info.tokenIds,
            info.preLeagueOwnerPercentage,
            info.preNewComerPercentage,
            info.leagueOwnerPercentage,
            info.newComerPercentage,
            info.setPercentageTime,
            info.currentVetoPoint,
            info.totalVetoPoint,
            info.premium,
            info.winnerNewComer
        );
    }

    //==============================================================================================================================
    //=============================================PRIVATE FUNTION==================================================================
    //==============================================================================================================================

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
        require(!league[leader].isLocked, "MercuryLeagueTournament: leagueLocked");
        uint256[] memory tokenIds = league[leader].tokenIds;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenId == tokenIds[i]) {
                revert("MercuryLeagueTournament: already joined");
            }
        }
        league[leader].tokenIds.push(tokenId);
        memberToLeader[msg.sender] = leader;
    }

    function addNewComer(uint256 tokenId, uint256 level) private isPotClaimable {
        levelToClaimTime[level] = block.timestamp + 15 minutes * 2 ^ (level - 1);
        levelToNewComerId[level] = tokenId;
        tokenIdPerLevel[level].push(tokenId);
    }

    function finalizeWinner(address newComer) private {
        address vault = LibBase.layout().protocol;
        address leader = memberToLeader[newComer];
        LeagueInfo storage leagueInfo = league[leader];
        uint256 denominator = 100;
        uint256 vaultValue = pot / denominator;
        payable(vault).transfer(vaultValue);
        pot = pot - vaultValue;
        isPaused = true;
        leagueInfo.isWinner = true;
        leagueInfo.winnerNewComer = newComer;
    }

    function isTimeFrozen() private view returns (bool) {
        for (uint256 level = 0; level <= LibBase.MAXLEVEL; level++) {
            if (levelToClaimTime[level] <= block.timestamp + 10 minutes) {
                return true;
            }
        }
        return false;
    }
    //dominating league definition: the league that's the newcomer of the shortest timer

    function isDominatingLeague(address leader) private view returns (bool) {
        uint256 shortestLevel = 0;
        uint256 shortestTimer = levelToClaimTime[shortestLevel];
        for (uint256 level = 1; level <= LibBase.MAXLEVEL; level++) {
            if (levelToClaimTime[level] < shortestTimer) {
                shortestTimer = levelToClaimTime[level];
                shortestLevel = level;
            }
        }
        uint256 newComerId = levelToNewComerId[shortestLevel];
        address member = _ownerOf(newComerId);
        return memberToLeader[member] == leader;
    }

    function verifySignature(address refereal, uint256 expirationTime, bytes calldata signature) internal {
        require(!signatureUsed[signature], "DAPPDistribution: signature used");
        bytes32 digest = keccak256(abi.encode(refereal, expirationTime));
        address recoveredSigner = ECDSA.recover(digest, signature);

        require(admin == recoveredSigner, "DAPPDistribution: invalid signature");
        require(block.timestamp <= expirationTime, "DAPPDistribution: signature expired");
        signatureUsed[signature] = true;
    }
}
