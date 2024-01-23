// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibPilotLeaderBoard.sol";
import {LibPilots} from "../protocol/storage/LibPilots.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PilotMileage is Initializable {
    address protocol;
    mapping(address => mapping(uint256 => uint256)) public lastSnapshotTime;
    function initialize(address _protocol) public initializer {
        protocol = _protocol;
    }

    event PilotMileageGain(address indexed collection, uint256 indexed tokenId, uint256 xp);

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    function canSnapshot(address collection, uint256 tokenId) public view returns (bool) {
        uint256 lastTime = lastSnapshotTime[collection][tokenId];
        if(lastTime == 0) {
            return true;
        }
        uint256 currentSecondsPST = (block.timestamp - 8 hours) % 24 hours;
        uint256 passOneAMPSTSeconds;
        if (currentSecondsPST >= 1 hours) {
            passOneAMPSTSeconds = currentSecondsPST - 1 hours;
        } else {
            passOneAMPSTSeconds = 23 hours + currentSecondsPST;
        }
        uint256 timestamp = block.timestamp - passOneAMPSTSeconds;
        if(timestamp > lastTime) {
            return true;
        }
        return false;
    }
    
    function pilotGainMileage(LibPilots.Pilot memory pilot, uint256 xp) public onlyProtocol {
        uint256 preXP = LibPilotLeaderBoard.getPilotRankingData(pilot);
        LibPilotLeaderBoard.setPilotRankingData(pilot, preXP+xp);
        emit PilotMileageGain(pilot.collectionAddress, pilot.pilotId, xp);
        if(canSnapshot(pilot.collectionAddress, pilot.pilotId)) {
                LibPilotLeaderBoard.snapshot(pilot);
                lastSnapshotTime[pilot.collectionAddress][pilot.pilotId] = block.timestamp;
        }
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
