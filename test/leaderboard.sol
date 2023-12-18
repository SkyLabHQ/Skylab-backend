// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";
// import "../contracts/leaderboard/PilotMileage.sol";
// import {LibPilots} from "../contracts/protocol/storage/LibPilots.sol";

// contract LeaderBoardTest is Test {
//     PilotMileage pm;

//     function setUp() public {
//         pm = new PilotMileage();
//         pm.initialize(address(this));
//     }

//     function test_pilotGainMileage() public {
//         LibPilots.Pilot memory pilot = LibPilots.Pilot(address(0x425A0CB30cE4a914B3fED2683f992F8B7C9e9214), 1);
//         pm.pilotGainMileage(pilot, 100);
//         pm.pilotGainMileage(pilot, 0);
//     }
// }
