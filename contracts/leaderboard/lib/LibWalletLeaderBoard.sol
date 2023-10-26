// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibPilots} from "../../protocol/storage/LibPilots.sol";

library LibWalletLeaderBoard {
    bytes32 constant LEADERBOARD = keccak256("mercury.pilot.leaderboard");

    struct LeaderBoard {
        mapping(address => uint256) pilotRankingData;
        mapping(uint256 => address[]) rankingDataGroups;
        mapping(address => uint256) rankingDataIndex;
        mapping(address => uint256) rankingDataGroupIndex;
        uint256[] groupLength;
        uint256 highestrankingDataGroupIndex;
    }

    function layout() internal pure returns (LeaderBoard storage ds) {
        bytes32 position = LEADERBOARD;
        assembly {
            ds.slot := position
        }
    }

    function setPilotRankingData(address wallet, uint256 rankingData) internal {
        layout().pilotRankingData[wallet] = rankingData;

        uint256 newIndex = convertToGroupIndex(uint256(layout().pilotRankingData[wallet]));

        uint256 oldIndex = layout().rankingDataGroupIndex[wallet];
        if (newIndex != oldIndex) {
            if (oldIndex > 0) {
                uint256 length = layout().groupLength[oldIndex];
                address swappedWallet = layout().rankingDataGroups[oldIndex][length - 1];
                uint256 index = layout().rankingDataIndex[wallet];
                layout().rankingDataGroups[oldIndex][index] = swappedWallet;
                layout().rankingDataGroups[oldIndex].pop();
                layout().rankingDataIndex[swappedWallet] = index;
                delete layout().rankingDataIndex[wallet];
                delete layout().rankingDataGroupIndex[wallet];
                layout().groupLength[oldIndex] = length - 1;
            }
            if (newIndex > 0) {
                layout().rankingDataGroups[newIndex].push(wallet);
                layout().rankingDataIndex[wallet] = layout().rankingDataGroups[newIndex].length - 1;
                layout().rankingDataGroupIndex[wallet] = newIndex;
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
}
