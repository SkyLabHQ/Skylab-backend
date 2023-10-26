// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PilotMileage} from "../../leaderboard/PilotMileage.sol";
import {PilotNetPoints} from "../../leaderboard/PilotNetPoints.sol";
import {PilotSessions} from "../../leaderboard/PilotSessions.sol";
import {PilotWinStreak} from "../../leaderboard/PilotWinStreak.sol";

library LibComponent {
    bytes32 constant SKYLABBASE_STORAGE_POSITION = keccak256("diamond.standard.componentindex.storage");

    struct ComponentIndexStorage {
        mapping(address => bool) isValidAviation;
        mapping(address => bool) isValidGame;
        mapping(address => bool) isValidPilotCollection;
        address mileage;
        address netPoints;
        address sessions;
        address winStreak;
    }

    event ValidAviation(address, bool);
    event ValidGame(address, bool);
    event ValidPilotCollection(address, bool);

    function layout() internal pure returns (ComponentIndexStorage storage cid) {
        bytes32 position = SKYLABBASE_STORAGE_POSITION;
        assembly {
            cid.slot := position
        }
    }

    function isValidAviation(address _aviation) internal view returns (bool) {
        return layout().isValidAviation[_aviation];
    }

    function isValidGame(address _game) internal view returns (bool) {
        return layout().isValidGame[_game];
    }

    function isValidPilotCollection(address _pilot) internal view returns (bool) {
        return layout().isValidPilotCollection[_pilot];
    }

    function getMileage() internal view returns (PilotMileage) {
        return PilotMileage(LibComponent.layout().mileage);
    }

    function getNetPoints() internal view returns (PilotNetPoints) {
        return PilotNetPoints(LibComponent.layout().netPoints);
    }

    function getSessions() internal view returns (PilotSessions) {
        return PilotSessions(LibComponent.layout().sessions);
    }

    function getWinStreak() internal view returns (PilotWinStreak) {
        return PilotWinStreak(LibComponent.layout().winStreak);
    }
}
