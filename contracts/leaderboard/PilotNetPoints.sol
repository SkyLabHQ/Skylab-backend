// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibWalletLeaderBoard.sol";
import "../protocol/storage/LibPilots.sol";

contract PilotNetPoints {
    address protocol;
    mapping(address => mapping(uint256 => int256)) pilotNetPoints;

    mapping(uint256 => LibPilots.Pilot[]) netPointsGroups;
    mapping(address => mapping(uint256 => uint256)) netPointsIndex;
    mapping(address => mapping(uint256 => uint256)) netPointsGroupIndex;
    uint256 highestNetPointsGroupIndex;

    constructor(address _protocol) {
        protocol = _protocol;
    }

    event PilotNetPointsGain(address indexed wallet, uint256 point);

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    function updatePilotNetPoints(address wallet, int256 pointsMoved) public onlyProtocol {
        uint256 point = LibWalletLeaderBoard.layout().pilotRankingData[wallet];
        if (pointsMoved < 0) {
            if (point >= uint256(-pointsMoved)) {
                point = point - uint256(-pointsMoved);
            } else {
                point = 0;
            }
        } else {
            point = point + uint256(pointsMoved);
        }
        LibWalletLeaderBoard.setPilotRankingData(wallet, point);
        emit PilotNetPointsGain(wallet, point);
    }

    function getPilotNetPointsGroup(uint256 index) public view returns (address[] memory) {
        return LibWalletLeaderBoard.layout().rankingDataGroups[index];
    }

    function getPilotNetPoints(address wallet) public view returns (uint256) {
        return LibWalletLeaderBoard.layout().pilotRankingData[wallet];
    }
}
