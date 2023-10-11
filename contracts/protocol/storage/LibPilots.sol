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
        mapping(address => mapping(uint256 => uint256)) pilotSessions;
        mapping(uint256 => Pilot[]) pilotMileageGroups;
        mapping(address => mapping(uint256 => uint256)) pilotGroupIndex;
        uint256 highestGroupIndex;
    }

    function layout() internal pure returns (PilotStorage storage ps) {
        bytes32 position = PILOT_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }
}
