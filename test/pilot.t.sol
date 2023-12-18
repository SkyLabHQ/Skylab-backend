// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import {Test, console2} from "forge-std/Test.sol";
// import {MercuryPilots} from "../contracts/protocol/MercuryPilots.sol";
// import {IERC721} from "../contracts/interfaces/IERC721.sol";

// contract PilotTest is Test {
//     MercuryPilots pilot;
//     address collection = address(0x425A0CB30cE4a914B3fED2683f992F8B7C9e9214);

//     function setUp() public {
//         pilot = new MercuryPilots();
//     }

//     function test_lose() public {
//         //pilot.setActivePilot(IERC721(collection), 1, address(this));
        
//         pilot.pilotWin(address(this), 10, 10);
//         pilot.pilotLose(address(this), 10, 10);
//         pilot.pilotWin(address(this), 40, 40);
//         pilot.pilotLose(address(this), 40, 40);
//         pilot.pilotWin(address(this), 100, 100);
//         pilot.pilotWin(address(this), 100, 200);
//         pilot.pilotLose(address(this), 150, 200);
//     }

//     fallback() external {}
// }