// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "../interfaces/IERC721.sol";
import {LibComponent} from "./storage/LibComponent.sol";
import {LibPilots} from "./storage/LibPilots.sol";

contract MercuryPilots {
    // Note: a pilot will remain in the mapping even if the pilot is sold, however, there should be no function that works when that's the case.
    function setActivePilot(IERC721 collection, uint256 tokenId, address owner) external {
        require(
            LibComponent.isValidPilotCollection(address(collection)),
            "MercuryPilots: collection is not a valid collection. "
        );
        LibPilots.layout().activePilot[owner] = LibPilots.Pilot(address(collection), tokenId);
        LibPilots.layout().recentlyUsedPilots[owner].push(LibPilots.Pilot(address(collection), tokenId));
    }

    // Note: should only be called if there's no other possible pilots; otherwise, use UI to guide player to switch to another pilot.
    function deactivatePilot() external {
        delete LibPilots.layout().activePilot[msg.sender];
    }

    function getActivePilot(address owner) public view returns (LibPilots.Pilot memory) {
        return LibPilots.layout().activePilot[owner];
    }

    function pilotWin(address player, uint256 mileage, uint256 pointsMoved) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = getActivePilot(player);
        if (pilot.collectionAddress != address(0)) {
            LibComponent.getMileage().pilotGainMileage(pilot, mileage);
            LibComponent.getSessions().increasePilotSessions(pilot);
            LibComponent.getNetPoints().updatePilotNetPoints(player, int256(pointsMoved));
            LibComponent.getWinStreak().updatePilotWinstreak(player, true);
        }
    }

    function pilotLose(address player, uint256 mileage, uint256 pointsMoved) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = getActivePilot(player);
        if (pilot.collectionAddress != address(0)) {
            LibComponent.getMileage().pilotGainMileage(pilot, mileage);
            LibComponent.getSessions().increasePilotSessions(pilot);
            LibComponent.getNetPoints().updatePilotNetPoints(player, -1 * int256(pointsMoved));
            LibComponent.getWinStreak().updatePilotWinstreak(player, false);
        }
    }

    function getRecentlyActivePilots(address player) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().recentlyUsedPilots[player];
    }
}
