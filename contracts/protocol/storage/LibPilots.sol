// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibPilots {
    bytes32 constant PILOT_STORAGE_POSITION = keccak256("diamond.standard.pilot.storage");

    struct Pilot {
        address collectionAddress;
        uint256 pilotId;
    }

    struct PilotStorage {
        mapping(address => Pilot) activePilot;
        mapping(address => Pilot[]) recentlyUsedPilots;
        mapping(address => mapping(uint256 => uint256)) pilotMileage;
        mapping(address => mapping(uint256 => int256)) pilotNetPoints;
        mapping(address => mapping(uint256 => uint256)) pilotCurWinStreak;
        mapping(address => mapping(uint256 => uint256)) pilotWinStreak;
        mapping(address => mapping(uint256 => uint256)) pilotSessions;

        mapping(uint256 => Pilot[]) mileageGroups;
        mapping(address => mapping(uint256 => uint256)) mileageIndex;
        mapping(address => mapping(uint256 => uint256)) mileageGroupIndex;
        uint256 highestMileageGroupIndex;

        mapping(uint256 => Pilot[]) netPointsGroups;
        mapping(address => mapping(uint256 => uint256)) netPointsIndex;
        mapping(address => mapping(uint256 => uint256)) netPointsGroupIndex;
        uint256 highestNetPointsGroupIndex;

        mapping(uint256 => Pilot[]) winStreakGroups;
        mapping(address => mapping(uint256 => uint256)) winStreakIndex;
        mapping(address => mapping(uint256 => uint256)) winStreakGroupIndex;
        uint256 highestWinStreakGroupIndex;
    }

    function layout() internal pure returns (PilotStorage storage ps) {
        bytes32 position = PILOT_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function convertToGroupIndex(uint256 xp) internal pure returns (uint256) {
        // if it's 0, it's in group 0; if it's 1, group 1; if it's 2 or 3, group 2...
        for (uint256 i = 0; i <= type(uint256).max; i++) {
            if (2 ** i > xp) {
                return i;
            }
        }
        return type(uint256).max;
    }
}
