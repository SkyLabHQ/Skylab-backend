// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibPilotLeaderBoard.sol";
import {LibPilots} from "../protocol/storage/LibPilots.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PilotMileage is Initializable {
    address protocol;
    uint256 public nextSnapshotTime;
    function initialize(address _protocol) public initializer {
        protocol = _protocol;
    }

    event PilotMileageGain(address indexed collection, uint256 indexed tokenId, uint256 xp);

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    function pilotGainMileage(LibPilots.Pilot memory pilot, uint256 xp) public onlyProtocol {
        if(block.timestamp >= nextSnapshotTime) {
                LibPilotLeaderBoard.snapshot(pilot);
                nextSnapshotTime = block.timestamp + 1 days;
        }
        uint256 preXP = LibPilotLeaderBoard.getPilotRankingData(pilot);
        LibPilotLeaderBoard.setPilotRankingData(pilot, preXP+xp);
        emit PilotMileageGain(pilot.collectionAddress, pilot.pilotId, xp);
    }

    function getPilotMileageGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilotLeaderBoard.layout().rankingDataGroups[index];
    }

    function getPilotMileage(address collection, uint256 tokenId) public view returns (uint256) {
        return LibPilotLeaderBoard.layout().pilotRankingData[collection][tokenId];
    }

    function getGroupLength(uint256 index) public view returns (uint256) {
        return LibPilotLeaderBoard.layout().groupLength[index];
    }

    function getSnapshotPilotMileageGroup(uint256 index) public view returns (LibPilots.Pilot[] memory) {
        return LibPilotLeaderBoard.snapshotLayout().rankingDataGroups[index];
    }

    function getSnapshotPilotMileage(address collection, uint256 tokenId) public view returns (uint256) {
        return LibPilotLeaderBoard.snapshotLayout().pilotRankingData[collection][tokenId];
    }

    function getSnapshotGroupLength(uint256 index) public view returns (uint256) {
        return LibPilotLeaderBoard.snapshotLayout().groupLength[index];
    }

    function getSnapshotHighestIndex() public view returns (uint256) {
        return LibPilotLeaderBoard.snapshotLayout().highestrankingDataGroupIndex;
    }
}
