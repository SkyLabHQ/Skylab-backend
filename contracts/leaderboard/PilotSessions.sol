// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibPilotLeaderBoard.sol";
import "../protocol/storage/LibPilots.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PilotSessions is Initializable {
    address protocol;
    mapping(address => mapping(uint256 => uint256)) pilotSessions;

    function initialize(address _protocol) public initializer {
        protocol = _protocol;
    }

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    function increasePilotSessions(LibPilots.Pilot memory pilot) public onlyProtocol {
        pilotSessions[pilot.collectionAddress][pilot.pilotId]++;
    }

    function getPilotSessions(address collectionAddress, uint256 pilotId) public view returns (uint256) {
        return pilotSessions[collectionAddress][pilotId];
    }
}
