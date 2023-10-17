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

    function getActivePilot(address owner) public returns (LibPilots.Pilot memory) {
        if (!isPilotOwned(LibPilots.layout().activePilot[owner], owner)) {
            delete LibPilots.layout().activePilot[owner];
        }
        return LibPilots.layout().activePilot[owner];
    }

    function viewActivePilot(address owner) public view returns (LibPilots.Pilot memory) {
        if (!isPilotOwned(LibPilots.layout().activePilot[owner], owner)) {
            return LibPilots.Pilot(address(0), 0);
        }
        return LibPilots.layout().activePilot[owner];
    }

    function pilotWin(address player, uint256 mileage, uint256 pointsMoved) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = getActivePilot(player);
        if (pilot.collectionAddress != address(0)) {
            pilotGainMileage(pilot, mileage);
            increasePilotSessions(pilot);
            updatePilotNetPoints(pilot, int256(pointsMoved));
            updatePilotWinstreak(pilot, true);
        }
    }

    function pilotLose(address player, uint256 mileage, uint256 pointsMoved) external {
        require(LibComponent.isValidAviation(msg.sender), "MercuryPilots: msg.sender is not a valid aviation. ");
        LibPilots.Pilot memory pilot = getActivePilot(player);
        if (pilot.collectionAddress != address(0)) {
            pilotGainMileage(pilot, mileage);
            increasePilotSessions(pilot);
            updatePilotNetPoints(pilot, -1 * int256(pointsMoved));
            updatePilotWinstreak(pilot, false);
        }
    }

    function pilotGainMileage(LibPilots.Pilot memory pilot, uint256 xp) private {
        LibPilots.PilotStorage storage ps = LibPilots.layout();
        ps.pilotMileage[pilot.collectionAddress][pilot.pilotId] += xp;

        uint256 newIndex = LibPilots.convertToGroupIndex(ps.pilotMileage[pilot.collectionAddress][pilot.pilotId]);
        uint256 oldIndex = ps.mileageGroupIndex[pilot.collectionAddress][pilot.pilotId];
        if (newIndex != oldIndex) {
            if (oldIndex > 0) {
                // don't handle group 0
                delete ps.mileageGroups[oldIndex][ps.mileageIndex[pilot.collectionAddress][pilot.pilotId]];
            }
            if (newIndex > 0) {
                ps.mileageGroups[newIndex].push(pilot);
                ps.mileageIndex[pilot.collectionAddress][pilot.pilotId] = ps.mileageGroups[newIndex].length - 1;
                ps.mileageGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            } else {
                delete ps.mileageIndex[pilot.collectionAddress][pilot.pilotId];
                delete ps.mileageGroupIndex[pilot.collectionAddress][pilot.pilotId];
            }

            if (newIndex > ps.highestMileageGroupIndex) {
                ps.highestMileageGroupIndex = newIndex;
            }
        }
    }

    function increasePilotSessions(LibPilots.Pilot memory pilot) private {
        LibPilots.layout().pilotSessions[pilot.collectionAddress][pilot.pilotId]++;
    }

    function updatePilotNetPoints(LibPilots.Pilot memory pilot, int256 pointsMoved) private {
        LibPilots.PilotStorage storage ps = LibPilots.layout();
        ps.pilotNetPoints[pilot.collectionAddress][pilot.pilotId] += pointsMoved;

        uint256 newIndex = 0;
        if (ps.pilotNetPoints[pilot.collectionAddress][pilot.pilotId] > 0) {
            newIndex = LibPilots.convertToGroupIndex(uint256(ps.pilotNetPoints[pilot.collectionAddress][pilot.pilotId]));
        }

        uint256 oldIndex = ps.netPointsGroupIndex[pilot.collectionAddress][pilot.pilotId];
        if (newIndex != oldIndex) {
            if (oldIndex > 0) {
                // don't handle group 0
                delete ps.netPointsGroups[oldIndex][ps.netPointsIndex[pilot.collectionAddress][pilot.pilotId]];
            }
            if (newIndex > 0) {
                ps.netPointsGroups[newIndex].push(pilot);
                ps.netPointsIndex[pilot.collectionAddress][pilot.pilotId] = ps.netPointsGroups[newIndex].length - 1;
                ps.netPointsGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            } else {
                delete ps.netPointsIndex[pilot.collectionAddress][pilot.pilotId];
                delete ps.netPointsGroupIndex[pilot.collectionAddress][pilot.pilotId];
            }

            if (newIndex > ps.highestNetPointsGroupIndex) {
                ps.highestNetPointsGroupIndex = newIndex;
            }
        }
    }

    function updatePilotWinstreak(LibPilots.Pilot memory pilot, bool won) private {
        LibPilots.PilotStorage storage ps = LibPilots.layout();
        if (won) {
            ps.pilotWinStreak[pilot.collectionAddress][pilot.pilotId] += 1;
        } else {
            ps.pilotWinStreak[pilot.collectionAddress][pilot.pilotId] = 0;
        }

        uint256 newIndex = LibPilots.convertToGroupIndex(ps.pilotWinStreak[pilot.collectionAddress][pilot.pilotId]);
        uint256 oldIndex = ps.winStreakGroupIndex[pilot.collectionAddress][pilot.pilotId];
        if (newIndex != oldIndex) {
            if (oldIndex > 0) {
                // don't handle group 0
                delete ps.winStreakGroups[oldIndex][ps.winStreakIndex[pilot.collectionAddress][pilot.pilotId]];
            }
            if (newIndex > 0) {
                ps.winStreakGroups[newIndex].push(pilot);
                ps.winStreakIndex[pilot.collectionAddress][pilot.pilotId] = ps.winStreakGroups[newIndex].length - 1;
                ps.winStreakGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            } else {
                delete ps.winStreakIndex[pilot.collectionAddress][pilot.pilotId];
                delete ps.winStreakGroupIndex[pilot.collectionAddress][pilot.pilotId];
            }

            if (newIndex > ps.highestWinStreakGroupIndex) {
                ps.highestWinStreakGroupIndex = newIndex;
            }
        }
    }

    function getPilotMileageGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().mileageGroups[index];
    }

    function getPilotMileage(address collection, uint256 tokenId) public view returns (uint256) {
        return LibPilots.layout().pilotMileage[collection][tokenId];
    }

    function getPilotNetPointsGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().netPointsGroups[index];
    }

    function getPilotNetPoints(address collection, uint256 tokenId) public view returns (int256) {
        return LibPilots.layout().pilotNetPoints[collection][tokenId];
    }

    function getPilotWinStreakGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilots.layout().winStreakGroups[index];
    }

    function getPilotWinStreak(address collection, uint256 tokenId) public view returns (uint256) {
        return LibPilots.layout().pilotWinStreak[collection][tokenId];
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
}
