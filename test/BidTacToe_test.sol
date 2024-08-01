// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";
import "lib/forge-std/src/console.sol";
import {BidTacToe} from "./BidTacToe.sol";

contract BidTacToe_Test is Test {
    BidTacToe btt;
    address player1;
    address player2;

    function setUp() public {
        player1 = address(1);
        player2 = address(2);
        vm.prank(player1);
        btt = new BidTacToe(BidTacToe.GameParams(3, 3, 3, 100, 1, 0, false, 45000), player1);
        btt.joinGame(player2);
    }

    function test_new_logic() public {
        uint256 salt = 0;
        vm.prank(player1);
        uint256 bid = 20;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player2);
        bid = 19;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player1);
        btt.revealBid(20, 0);
        vm.prank(player2);
        btt.revealBid(19, 0);

        vm.prank(player1);
        bid = 20;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player2);
        bid = 19;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player1);
        btt.revealBid(20, 0);
        vm.prank(player2);
        btt.revealBid(19, 0);

        vm.prank(player1);
        bid = 20;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player2);
        bid = 62;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player1);
        btt.revealBid(20, 0);
        vm.prank(player2);
        btt.revealBid(62, 0);

        assertEq(btt.balances(player2), 0);
        assertEq(btt.gameStates(player1), 10);
        assertEq(btt.gameStates(player2), 11);
    }
    
    function test_both_zero() public {
        uint256 salt = 0;
        vm.prank(player1);
        uint256 bid = 1;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player2);
        bid = 1;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player1);
        btt.revealBid(1, 0);
        vm.prank(player2);
        btt.revealBid(1, 0);

        salt = 0;
        vm.prank(player1);
        bid = 99;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player2);
        bid = 99;
        btt.commitBid(uint256(keccak256(abi.encodePacked(bid, salt))));
        vm.prank(player1);
        btt.revealBid(99, 0);
        vm.prank(player2);
        btt.revealBid(99, 0);

        assertEq(btt.balances(player1), 0);
        assertEq(btt.balances(player2), 0);
        assertEq(btt.gameStates(btt.nextDrawWinner()), 11);
    }
}
