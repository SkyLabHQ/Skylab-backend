// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "../interfaces/IERC721.sol";
import {LibComponent} from "./storage/LibComponent.sol";
import {LibPilots} from "./storage/LibPilots.sol";

contract MercuryPilots {
    // Note: a pilot will remain in the mapping even if the pilot is sold, however, there should be no function that works when that's the case.
    function setActivePilot(IERC721 collection, uint256 tokenId, address owner) external {
        require(LibComponent.isValidPilot(address(collection)), "MercuryPilots: collection is not a valid collection. ");
        require(
            msg.sender == collection.ownerOf(tokenId) || collection.isApprovedForAll(owner, msg.sender)
                || collection.getApproved(tokenId) == msg.sender,
            "MercuryPilots: msg.sender is not approved or owner. "
        );
        LibPilots.layout().activePilot[owner] = LibPilots.Pilot(address(collection), tokenId);
        require(
            isPilotOwned(LibPilots.layout().activePilot[owner], owner),
            "MercuryPilots: owner parameter is not token owner. "
        );
        LibPilots.layout().recentlyUsedPilots[owner].push(LibPilots.Pilot(address(collection), tokenId));
    }

    // Note: should only be called if there's no other possible pilots; otherwise, use UI to guide player to switch to another pilot.
    function deactivatePilot() external {
        delete LibPilots.layout().activePilot[msg.sender];
    }

    function getActivePilot(address owner) public view returns (LibPilots.Pilot memory) {
        return LibPilots.layout().activePilot[owner];
    }

    function viewActivePilot(address owner) private returns (LibPilots.Pilot memory) {
        if (!isPilotOwned(getActivePilot(owner), owner)) {
            delete LibPilots.layout().activePilot[owner];
        }
        return LibPilots.layout().activePilot[owner];
    }

    function pilotGainMileage(address player, uint256 xp) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = viewActivePilot(player);
        LibPilots.PilotStorage storage ps = LibPilots.layout();
        ps.pilotMileage[pilot.collectionAddress][pilot.pilotId] += xp;
        uint256 newIndex = findMileageGroup(ps.pilotMileage[pilot.collectionAddress][pilot.pilotId]);
        if (newIndex != ps.pilotGroupIndex[pilot.collectionAddress][pilot.pilotId]) {
            ps.pilotMileageGroups[newIndex].push(pilot);
            ps.pilotGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            if (newIndex > ps.highestGroupIndex) {
                ps.highestGroupIndex = newIndex;
            }
        }
    }

    function increasePilotSessions(address player) external {
        require(LibComponent.isValidGame(msg.sender), "MercuryPilots: msg.sender is not a valid game. ");
        LibPilots.Pilot memory pilot = viewActivePilot(player);
        LibPilots.layout().pilotSessions[pilot.collectionAddress][pilot.pilotId]++;
    }

    function getPilotMileageGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().pilotMileageGroups[index];
    }

    function getPilotMileage(address collection, uint256 tokenId) public view returns(uint256) {
        return LibPilots.layout().pilotMileage[collection][tokenId];
    }

    function getRecentlyActivePilots(address player) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().recentlyUsedPilots[player];
    }

    function getPilotSessions(address player) public view returns (uint256) {
        LibPilots.Pilot memory pilot = LibPilots.layout().activePilot[player];
        return LibPilots.layout().pilotSessions[pilot.collectionAddress][pilot.pilotId];
    }

    function isPilotOwned(LibPilots.Pilot memory pilot, address owner) private view returns (bool) {
        if (pilot.collectionAddress == address(0)) {
            return false;
        }
        return IERC721(pilot.collectionAddress).ownerOf(pilot.pilotId) == owner;
    }

    function findMileageGroup(uint256 xp) private pure returns (uint256) {
        for (uint256 i = 0; i <= type(uint256).max; i++) {
            if (2 ** i > xp) {
                return i;
            }
        }
        return type(uint256).max;
    }
}
