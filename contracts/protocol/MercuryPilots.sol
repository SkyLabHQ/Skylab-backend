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
            checkPilotOwned(LibPilots.layout().activePilot[owner], owner),
            "MercuryPilots: owner parameter is not token owner. "
        );
    }

    // Note: should only be called if there's no other possible pilots; otherwise, use UI to guide player to switch to another pilot.
    function deactivatePilot() external {
        delete LibPilots.layout().activePilot[msg.sender];
    }

    function getActivePilot(address owner) public view returns (LibPilots.Pilot memory) {
        require(
            checkPilotOwned(LibPilots.layout().activePilot[owner], owner),
            "MercuryPilots: active pilot is not owned by owner"
        );
        return LibPilots.layout().activePilot[owner];
    }

    function pilotGainXP(address player, uint256 xp) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = getActivePilot(player);
        LibPilots.PilotStorage storage ps = LibPilots.layout();
        ps.pilotXP[pilot.collectionAddress][pilot.pilotId] += xp;
        uint256 newIndex = findXPGroup(ps.pilotXP[pilot.collectionAddress][pilot.pilotId]);
        if (newIndex != ps.pilotGroupIndex[pilot.collectionAddress][pilot.pilotId]) {
            ps.pilotXPGroups[newIndex].push(pilot);
            ps.pilotGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            if (newIndex > ps.highestGroupIndex) {
                ps.highestGroupIndex = newIndex;
            }
        }
    }

    function getPilotXPGroup(uint256 index) external view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().pilotXPGroups[index];
    }

    function checkPilotOwned(LibPilots.Pilot memory pilot, address owner) private view returns (bool) {
        return IERC721(pilot.collectionAddress).ownerOf(pilot.pilotId) == owner;
    }

    function findXPGroup(uint256 xp) private pure returns (uint256) {
        for (uint256 i = 0; i <= type(uint256).max; i++) {
            if (2 ** i > xp) {
                return i;
            }
        }
        return type(uint256).max;
    }
}
