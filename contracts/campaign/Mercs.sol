// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../leaderboard/PilotMileage.sol";
import "./BabyMercs.sol";
import "@solidstate/token/ERC721/SolidStateERC721.sol";

contract Mercs is SolidStateERC721 {
    BabyMercs public babyMercs;
    PilotMileage public leaderBoard;
    mapping(uint256 => uint256) public babyMercsUP;
    mapping(uint256 => uint256) public lastClaimTime;
    uint256 public nextTokenId;

    function claimUpgradeablePoints(uint256 tokenId) public {
        require(canClaim(tokenId), "Mercs: Wait until next window");
        (bool isFiftyPercentage, uint256 totalMileage) = isFiftyPercentageAndTotalMileage(tokenId);
        require(isFiftyPercentage, "Mercs: not fifty percentage");
        require(babyMercs.ownerOf(tokenId) == msg.sender, "Mercs: not owner");
        uint256 upgradePoints = PilotMileage(leaderBoard).getPilotMileage(address(babyMercs), tokenId) / totalMileage * 100;
        babyMercsUP[tokenId] += upgradePoints;
        lastClaimTime[tokenId] = block.timestamp;
    }

    function canClaim(uint256 tokenId) public view returns (bool) {
        if(lastClaimTime[tokenId] == 0) {
            return true;
        }
        uint256 currentSecondsPST = (block.timestamp - 8 hours) % 24 hours;
        bool isAfterResetTime = currentSecondsPST >= 1 hours;
        bool is24HoursPast = block.timestamp - lastClaimTime[tokenId] >= 24 hours;
        return isAfterResetTime && is24HoursPast;
    }
    
    function mint(uint256 tokenId) public {
        require(babyMercsUP[tokenId] >= 100, "Mercs: upgrade point does not meets requirement");
        require(babyMercs.ownerOf(tokenId) == msg.sender, "not owner");
        babyMercsUP[tokenId] -= 100;
        babyMercs.burn(tokenId);
        _safeMint(msg.sender, nextTokenId + 1);
        nextTokenId++;
    }

    function isFiftyPercentageAndTotalMileage(uint256 tokenId) private returns (bool, uint256) {
        uint256 mileage = leaderBoard.getSnapshotPilotMileage(address(babyMercs), tokenId);
        uint256 totalPilot;
        uint256 highestIndex = leaderBoard.getSnapshotHighestIndex();
        for (uint256 i = highestIndex; i > 0; i--) {
            totalPilot += leaderBoard.getSnapshotGroupLength(i);
        }
        uint256 midPilot = (totalPilot + 1) / 2;
        uint256 groupMid;
        uint256 midIndex;
        uint256 accumulate = 0;
        for (uint256 i = highestIndex; i > 0; i--) {
            uint256 groupLength = leaderBoard.getGroupLength(i);
            if(accumulate + groupLength >= midPilot) {
                midIndex = i;
                groupMid = midPilot - accumulate;
                break;
            }
            accumulate += groupLength;
        }
        LibPilots.Pilot[] memory pilotGroup = leaderBoard.getSnapshotPilotMileageGroup(midIndex);
        uint256[] memory group;
        for(uint256 i = 0; i < pilotGroup.length; i++) {
            group[i] = leaderBoard.getSnapshotPilotMileage(pilotGroup[i].collectionAddress, pilotGroup[i].pilotId);
        }
        quickSort(group,0,int256(group.length - 1));
        uint256 midMileage = group[groupMid];
        uint256 totalMileage;
        for(uint256 i = groupMid; i < group.length; i++) {
            totalMileage += group[i];
        }
        for(uint256 i = midIndex + 1; i <= highestIndex; i++) {
            LibPilots.Pilot[] memory pilotGroups = leaderBoard.getSnapshotPilotMileageGroup(i);
            for(uint256 j = 0; j < pilotGroups.length; j++) {
                totalMileage += leaderBoard.getSnapshotPilotMileage(pilotGroups[j].collectionAddress, pilotGroups[j].pilotId);
            }
        }
        return (mileage >= midMileage, totalMileage);
    }

    function quickSort(uint256[] memory _arr, int256 left, int256 right) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = _arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (_arr[uint256(i)] < pivot) i++;
            while (pivot < _arr[uint256(j)]) j--;
            if (i <= j) {
                (_arr[uint256(i)], _arr[uint256(j)]) = (_arr[uint256(j)], _arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(_arr, left, j);
        if (i < right) quickSort(_arr, i, right);
    }
}