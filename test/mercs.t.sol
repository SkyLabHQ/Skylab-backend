// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MercuryPilots} from "../contracts/protocol/MercuryPilots.sol";
import {IERC721} from "../contracts/interfaces/IERC721.sol";
import { Mercs } from "../contracts/campaign/Mercs.sol";
import { PilotMileage } from "../contracts/leaderboard/PilotMileage.sol";
import { LibPilots } from "../contracts/protocol/storage/LibPilots.sol";

// to pass this test, have to comment out the modifier onlyProtocol pilotGainMileage function
// and LibDiamond.enforceIsContractOwner() initialize function in PilotMileage.sol 
contract MercsTest is Test {
    Mercs mercs;
    PilotMileage pilotMileage;
    address collectionAddress = address(0xabcd);

    function setUp() public {
        pilotMileage = new PilotMileage();
        mercs = new Mercs();
        mercs.initialize(address(pilotMileage), collectionAddress);
        LibPilots.Pilot memory p1 = LibPilots.Pilot(collectionAddress, 1);
        LibPilots.Pilot memory p2 = LibPilots.Pilot(collectionAddress, 2);
        LibPilots.Pilot memory p3 = LibPilots.Pilot(collectionAddress, 3);
        LibPilots.Pilot memory p4 = LibPilots.Pilot(collectionAddress, 4);
        LibPilots.Pilot memory p5 = LibPilots.Pilot(collectionAddress, 5);
        LibPilots.Pilot memory p6 = LibPilots.Pilot(collectionAddress, 6);
        LibPilots.Pilot memory p7 = LibPilots.Pilot(collectionAddress, 7);
        LibPilots.Pilot memory p8 = LibPilots.Pilot(collectionAddress, 8);
        LibPilots.Pilot memory p9 = LibPilots.Pilot(collectionAddress, 9);
        LibPilots.Pilot memory p10 = LibPilots.Pilot(collectionAddress, 10);
        LibPilots.Pilot memory p11 = LibPilots.Pilot(collectionAddress, 11);
        LibPilots.Pilot memory p12 = LibPilots.Pilot(collectionAddress, 12);
        LibPilots.Pilot memory p13 = LibPilots.Pilot(collectionAddress, 13);
        LibPilots.Pilot memory p14 = LibPilots.Pilot(collectionAddress, 14);
        LibPilots.Pilot memory p15 = LibPilots.Pilot(collectionAddress, 15);
        LibPilots.Pilot memory p16 = LibPilots.Pilot(collectionAddress, 16);
        LibPilots.Pilot memory p17 = LibPilots.Pilot(collectionAddress, 17);
        LibPilots.Pilot memory p18 = LibPilots.Pilot(collectionAddress, 18);
        vm.warp(1705343540);
        pilotMileage.pilotGainMileage(p1 ,1);
        pilotMileage.pilotGainMileage(p2 ,2);
        pilotMileage.pilotGainMileage(p3 ,3);
        pilotMileage.pilotGainMileage(p4 ,4);
        pilotMileage.pilotGainMileage(p5 ,5);
        pilotMileage.pilotGainMileage(p6 ,6);
        pilotMileage.pilotGainMileage(p7 ,7);
        pilotMileage.pilotGainMileage(p8 ,8);
        pilotMileage.pilotGainMileage(p9 ,9);
        pilotMileage.pilotGainMileage(p10 ,10);
        pilotMileage.pilotGainMileage(p11 ,11);
        pilotMileage.pilotGainMileage(p12 ,12);
        pilotMileage.pilotGainMileage(p13 ,13);
        pilotMileage.pilotGainMileage(p14 ,14);
        pilotMileage.pilotGainMileage(p15 ,15);
        pilotMileage.pilotGainMileage(p16 ,16);
        pilotMileage.pilotGainMileage(p17 ,17);
        pilotMileage.pilotGainMileage(p18 ,18);
        (bool isFifty, uint256 totalMileage) = mercs.isFiftyPercentageAndTotalMileage(1);
        assertEq(isFifty, false);
        assertEq(totalMileage, 126);
        (bool isFifty2,) = mercs.isFiftyPercentageAndTotalMileage(9);
        assertEq(isFifty2, false);
        (bool isFifty3,) = mercs.isFiftyPercentageAndTotalMileage(10);
        assertEq(isFifty3, true);
    } 

    function test_gain() public {
        setUp();
    }
}