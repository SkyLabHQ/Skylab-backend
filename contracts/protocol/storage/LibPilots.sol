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
