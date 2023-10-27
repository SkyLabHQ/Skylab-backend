// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/LibWalletLeaderBoard.sol";
import "../protocol/storage/LibPilots.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract PilotWinStreak is Initializable {
    address public protocol;
    mapping(address => uint256) public pilotCurWinStreak;

    function initialize(address _protocol) public initializer {
        protocol = _protocol;
    }

    modifier onlyProtocol() {
        require(msg.sender == protocol, "Only protocol can call this function");
        _;
    }

    event PilotWinStreakGain(address indexed wallet, uint256 winStreak);

    function updatePilotWinstreak(address wallet, bool won) public onlyProtocol {
        if (won) {
            pilotCurWinStreak[wallet] += 1;
        } else {
            pilotCurWinStreak[wallet] = 0;
        }

        if (pilotCurWinStreak[wallet] > LibWalletLeaderBoard.layout().pilotRankingData[wallet]) {
            LibWalletLeaderBoard.setPilotRankingData(wallet, pilotCurWinStreak[wallet]);
            emit PilotWinStreakGain(wallet, pilotCurWinStreak[wallet]);
        }
    }

    function getPilotWinStreakGroup(uint256 index) public view returns (address[] memory) {
        return LibWalletLeaderBoard.layout().rankingDataGroups[index];
    }

    function getPilotWinStreak(address wallet) public view returns (uint256) {
        return LibWalletLeaderBoard.layout().pilotRankingData[wallet];
    }

    function getGroupLength(uint256 index) public view returns (uint256) {
        return LibWalletLeaderBoard.layout().groupLength[index];
    }
}
