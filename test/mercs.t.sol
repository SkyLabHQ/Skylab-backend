// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {MercuryPilots} from "../contracts/protocol/MercuryPilots.sol";
import {IERC721} from "../contracts/interfaces/IERC721.sol";
import {Mercs} from "../contracts/campaign/Mercs.sol";
import {PilotMileage} from "../contracts/leaderboard/PilotMileage.sol";
import {LibPilots} from "../contracts/protocol/storage/LibPilots.sol";

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
        vm.warp(1706151148);
        assertEq(mercs.canClaim(1), true);
        vm.warp(1706151271);
        assertEq(mercs.canClaim(1), false);
        vm.warp(1706260422);
        assertEq(mercs.canClaim(1), true);
        LibPilots.Pilot memory p0 = LibPilots.Pilot(collectionAddress, 0);
        LibPilots.Pilot memory p01 = LibPilots.Pilot(collectionAddress, 10);
        LibPilots.Pilot memory p001 = LibPilots.Pilot(collectionAddress, 100);
        LibPilots.Pilot memory p0001 = LibPilots.Pilot(collectionAddress, 1000);
        LibPilots.Pilot memory p00001 = LibPilots.Pilot(collectionAddress, 10000);
        LibPilots.Pilot memory p000001 = LibPilots.Pilot(collectionAddress, 100000);
        LibPilots.Pilot memory p1 = LibPilots.Pilot(collectionAddress, 1);
        LibPilots.Pilot memory p2 = LibPilots.Pilot(collectionAddress, 2);
        LibPilots.Pilot memory p3 = LibPilots.Pilot(collectionAddress, 3);
        LibPilots.Pilot memory p4 = LibPilots.Pilot(collectionAddress, 4);
        vm.warp(1705343540);
        pilotMileage.pilotGainMileage(p0, 0);
        pilotMileage.pilotGainMileage(p01, 0);
        pilotMileage.pilotGainMileage(p001, 0);
        pilotMileage.pilotGainMileage(p0001, 0);
        pilotMileage.pilotGainMileage(p00001, 0);
        pilotMileage.pilotGainMileage(p000001, 0);
        pilotMileage.pilotGainMileage(p1, 1);
        pilotMileage.pilotGainMileage(p2, 2);
        pilotMileage.pilotGainMileage(p3, 3);
        pilotMileage.pilotGainMileage(p4, 4);
        (bool isFifty, uint256 totalMileage) = mercs.isFiftyPercentageAndTotalMileage(0);
        assertEq(isFifty, false);
        assertEq(totalMileage, 7);
        (bool isFifty1,) = mercs.isFiftyPercentageAndTotalMileage(10);
        assertEq(isFifty1, false);
        (bool isFifty2,) = mercs.isFiftyPercentageAndTotalMileage(100);
        assertEq(isFifty2, false);
        (bool isFifty3,) = mercs.isFiftyPercentageAndTotalMileage(1000);
        assertEq(isFifty3, false);
        (bool isFifty4,) = mercs.isFiftyPercentageAndTotalMileage(10000);
        assertEq(isFifty4, false);
        (bool isFifty5,) = mercs.isFiftyPercentageAndTotalMileage(100000);
        assertEq(isFifty5, false);
        (bool isFifty6,) = mercs.isFiftyPercentageAndTotalMileage(1);
        assertEq(isFifty6, false);
        (bool isFifty7,) = mercs.isFiftyPercentageAndTotalMileage(2);
        assertEq(isFifty7, false);
        (bool isFifty8,) = mercs.isFiftyPercentageAndTotalMileage(3);
        assertEq(isFifty8, true);
        (bool isFifty9,) = mercs.isFiftyPercentageAndTotalMileage(4);
        assertEq(isFifty9, true);
    }

    function test_gain() public {
        setUp();
    }
}
