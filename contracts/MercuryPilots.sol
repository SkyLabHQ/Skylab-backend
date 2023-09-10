// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MercuryPilots is Ownable {
    struct Pilot {
        address collectionAddress;
        uint pilotId;
    }

    mapping(address => Pilot) private activePilot;
    mapping(address => mapping(uint => uint)) public pilotXP;

    mapping(uint => Pilot[]) private pilotXPGroups;
    mapping(address => mapping(uint => uint)) public pilotGroupIndex;
    uint public highestGroupIndex = 0;

    // Note: a pilot will remain in the mapping even if the pilot is sold, however, there should be no function that works when that's the case. 
    function setActivePilot(ERC721 collection, uint tokenId, address owner) external {
        // TODO: Check that collection is a valid collection against central index
        require(msg.sender == collection.ownerOf(tokenId) || collection.isApprovedForAll(owner, msg.sender) || collection.getApproved(tokenId) == msg.sender, "MercuryPilots: msg.sender is not approved or owner. ");
        activePilot[owner] = Pilot(address(collection), tokenId);
        require(checkPilotOwned(activePilot[owner], owner), "MercuryPilots: owner parameter is not token owner. ");
    }

    // Note: should only be called if there's no other possible pilots; otherwise, use UI to guide player to switch to another pilot. 
    function deactivatePilot() external {
        delete activePilot[msg.sender];
    }

    function getActivePilot(address owner) public view returns (Pilot memory) {
        require(checkPilotOwned(activePilot[owner], owner), "MercuryPilots: active pilot is not owned by owner");
        return activePilot[owner];
    }

    function pilotGainXP(address player, uint xp) external {
        // TODO: Check that msg.sender is a valid MercuryBase
        Pilot memory pilot = getActivePilot(player);
        pilotXP[pilot.collectionAddress][pilot.pilotId] += xp;
        uint newIndex = findXPGroup(pilotXP[pilot.collectionAddress][pilot.pilotId]);
        if (newIndex != pilotGroupIndex[pilot.collectionAddress][pilot.pilotId]) {
            pilotXPGroups[newIndex].push(pilot);
            pilotGroupIndex[pilot.collectionAddress][pilot.pilotId] = newIndex;
            if (newIndex > highestGroupIndex) {
                highestGroupIndex = newIndex;
            }
        }
    }

    function getPilotXPGroup(uint index) external view returns (Pilot[] memory) {
        return pilotXPGroups[index];
    }

    function checkPilotOwned(Pilot memory pilot, address owner) private view returns (bool) {
        return ERC721(pilot.collectionAddress).ownerOf(pilot.pilotId) == owner;
    }

    function findXPGroup(uint xp) private pure returns (uint) {
        for (uint i = 0; i <= type(uint256).max; i++) {
            if (2**i > xp) {
                return i;
            }
        }
        return type(uint256).max;
    }
}