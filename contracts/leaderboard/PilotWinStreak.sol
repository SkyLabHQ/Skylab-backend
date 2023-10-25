// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibWalletLeaderBoard.sol";
import "../protocol/storage/LibPilots.sol";

contract PilotWinStreak {
    address public protocol;
    mapping(address => uint256) public pilotCurWinStreak;

    constructor(address _protocol) {
        protocol = _protocol;
    }

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    function updatePilotWinstreak(address wallet, bool won) public onlyProtocol {
        if (won) {
            pilotCurWinStreak[wallet] += 1;
        } else {
            pilotCurWinStreak[wallet] = 0;
        }

        if (pilotCurWinStreak[wallet] > LibWalletLeaderBoard.layout().pilotRankingData[wallet]) {
            LibWalletLeaderBoard.setPilotGainrankingData(wallet, pilotCurWinStreak[wallet]);
        }
    }

    function getPilotWinStreakGroup(uint256 index) public view returns (address[] memory) {
        return LibWalletLeaderBoard.layout().rankingDataGroups[index];
    }

    function getPilotWinStreak(address wallet) public view returns (uint256) {
        return LibWalletLeaderBoard.layout().pilotRankingData[wallet];
    }
}
