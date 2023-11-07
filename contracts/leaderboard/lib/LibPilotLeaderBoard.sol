// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibPilots} from "../../protocol/storage/LibPilots.sol";

library LibPilotLeaderBoard {
    bytes32 constant LEADERBOARD = keccak256("mercury.pilot.leaderboard");

    struct LeaderBoard {
        mapping(address => mapping(uint256 => uint256)) pilotRankingData;
        mapping(uint256 => LibPilots.Pilot[]) rankingDataGroups;
        mapping(address => mapping(uint256 => uint256)) rankingDataIndex;
        mapping(address => mapping(uint256 => uint256)) rankingDataGroupIndex;
        mapping(uint256 => uint256) groupLength;
        uint256 highestrankingDataGroupIndex;
    }

    function layout() internal pure returns (LeaderBoard storage ds) {
        bytes32 position = LEADERBOARD;
        assembly {
            ds.slot := position
        }
    }

    function setPilotRankingData(LibPilots.Pilot memory pilot, uint256 rankingData) internal {
        layout().pilotRankingData[pilot.collectionAddress][pilot.pilotId] = rankingData;

        uint256 newIndex = convertToGroupIndex(rankingData);
        uint256 oldIndex = layout().rankingDataGroupIndex[pilot.collectionAddress][pilot.pilotId];
        if (newIndex != oldIndex) {
            if (oldIndex > 0) {
                uint256 length = layout().rankingDataGroups[oldIndex].length;
                LibPilots.Pilot memory swappedPilot = layout().rankingDataGroups[oldIndex][length - 1];
                uint256 index = layout().rankingDataIndex[pilot.collectionAddress][pilot.pilotId];
                layout().rankingDataGroups[oldIndex][index] = swappedPilot;
                layout().rankingDataGroups[oldIndex].pop();
                layout().rankingDataIndex[swappedPilot.collectionAddress][swappedPilot.pilotId] = index;
                delete layout().rankingDataIndex[pilot.collectionAddress][pilot.pilotId];
                delete layout().rankingDataGroupIndex[pilot.collectionAddress][pilot.pilotId];
                layout().groupLength[oldIndex] = length - 1;
            }
            if (newIndex > 0) {
                layout().rankingDataGroups[newIndex].push(pilot);
                layout().rankingDataIndex[pilot.collectionAddress][pilot.pilotId] =
                    layout().rankingDataGroups[newIndex].length - 1;
                layout().rankingDataGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
                layout().groupLength[newIndex] = layout().rankingDataGroups[newIndex].length;
            }

            if (newIndex > layout().highestrankingDataGroupIndex) {
                layout().highestrankingDataGroupIndex = newIndex;
            }
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

    function getPilotRankingData(LibPilots.Pilot memory pilot) internal view returns (uint256) {
        return layout().pilotRankingData[pilot.collectionAddress][pilot.pilotId];
    }
}
