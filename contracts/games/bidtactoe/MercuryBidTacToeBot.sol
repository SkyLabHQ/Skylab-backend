// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BidTacToe} from "./BidTacToe.sol";

// Only works for 3x3
contract MercuryBidTacToeBot {
    
    uint[3][8] private winFormations;

    constructor() {
        winFormations[0] = [0,1,2];
        winFormations[1] = [3,4,5];
        winFormations[2] = [6,7,8];
        winFormations[3] = [0,3,6];
        winFormations[4] = [1,4,7];
        winFormations[5] = [2,5,8];
        winFormations[6] = [0,4,8];
        winFormations[7] = [2,4,6];
    }


    function bidAndReveal(BidTacToe game)
        external
    {
        require(game.player1() == msg.sender, "BidTacToeBot: msg.sender is not player1");

        uint bid = analyzeBid(game);
        game.commitBid(uint256(keccak256(abi.encodePacked(bid, uint(0)))));
        game.revealBid(bid, 0);
    }

    function analyzeBid(BidTacToe game) internal view returns (uint) {
        address[] memory grid = game.getGrid();
        uint currentSelectedGrid = game.currentSelectedGrid();
        uint myBalance = game.balances(address(this));
        uint opponentBalance = game.balances(msg.sender);
        uint myOccupiedGridCounts = game.occupiedGridCounts(address(this));
        uint opponentOccupiedGridCounts = game.occupiedGridCounts(msg.sender);

        grid[currentSelectedGrid] = address(this);
        uint pp_win = calculatePositionalPower(grid, address(this), msg.sender);
        // certain win
        if ((pp_win > 1000 || myOccupiedGridCounts + 1 >= 5) && myBalance > opponentBalance) {
            return opponentBalance + 1;
        }

        grid[currentSelectedGrid] = msg.sender;
        uint pp_lose = 0;
        if (opponentOccupiedGridCounts + 1 < 5) {
            // not certain loss
            pp_lose = calculatePositionalPower(grid, address(this), msg.sender);
        }

        uint optimalBid = 0;
        uint bestScore = 0;
        for (uint bid = 0; bid <= myBalance; bid++) {
            uint win_rate = 1000;
            if (opponentBalance > 0 && bid <= opponentBalance) {
                win_rate = 1000 * bid / (opponentBalance+1);
            }
            
            // win case
            uint ps = pp_win * calculateResourcePower(bid, myBalance, opponentBalance, true) * win_rate;
            // lose case
            ps += pp_lose * calculateResourcePower(bid, myBalance, opponentBalance, false) * (1000 - win_rate);

            if (ps > bestScore) {
                bestScore = ps;
                optimalBid = bid;
            }
        }

        return randomize(optimalBid, myBalance);
    }

    function calculatePositionalPower(address[] memory grid, address player1, address player2) internal view returns (uint) {
        uint player1Count = 0;
        uint player2Count = 0;

        uint player1GridCount;
        uint player2GridCount;
        for (uint i = 0; i < 8; i++) {
            (player1GridCount, player2GridCount) = lineOwnership(grid, player1, player2, winFormations[i]);
            if (player1GridCount == 3) {
                return 1001;
            }
            if (player2GridCount == 3) {
                return 0;
            }

            if (player1GridCount == 0 && player2GridCount == 0) {
                player1Count += 1;
                player2Count += 1;
            } else if (player1GridCount == 0 && player2GridCount > 0) {
                player2Count += 1;
            } else if (player1GridCount > 0 && player2GridCount == 0) {
                player1Count += 1;
            }
        }
        // plus 1 represents winning by occupying more
        return 1000 * (player1Count + 1) / (player1Count + player2Count + 2);
    }

    function lineOwnership(address[] memory grid, address player1, address player2, uint[3] memory indexes) internal pure returns (uint, uint) {
        return (gridOwnership(grid, player1, indexes[0]) + gridOwnership(grid, player1, indexes[1]) + gridOwnership(grid, player1, indexes[2]), gridOwnership(grid, player2, indexes[0]) + gridOwnership(grid, player2, indexes[1]) + gridOwnership(grid, player2, indexes[2]));
    }

    function gridOwnership(address[] memory grid, address player, uint index) internal pure returns (uint) {
        if (grid[index] == player) {
            return 1;
        }
            
        return 0;
    }

    function calculateResourcePower(uint bid, uint myBalance, uint opponentBalance, bool win) internal pure returns (uint) {
        if (myBalance == bid) {
            return 0;
        }
        // if opponent beats me, slash to half
        if (!win) {
            opponentBalance = opponentBalance / 2;
        }
        if (opponentBalance > bid / 2) {
            opponentBalance = opponentBalance - bid / 2;
        } else {
            opponentBalance = 0;
        }
        return 1000 * (myBalance - bid) / (myBalance + opponentBalance - bid);
    }

    function randomize(uint bid, uint myBalance) internal view returns (uint) {
        // get a random number around 128, standard deviation 8
        uint256 result = _countOnes(uint256(keccak256(abi.encodePacked(bid + block.timestamp))));
        // transform it to a number around bid * 100; lower bound it at -4*stdev
        uint256 transformed = 0;
        if (result <= 128) {
            result = result - 96;
            if (result < 0) result = 0;
            transformed = 100 * result * bid / 32;
        } else {
            result = result - 128;
            if (result > 32) result = 32;
            transformed = 100 * result * (myBalance - bid) / 32 + 100 * bid;
        }
        // remove the 0's but round to the nearist
        if (transformed - transformed / 100 * 100 > 50) {
            transformed = transformed / 100 + 1;
        } else {
            transformed = transformed / 100;
        }
        if (transformed > myBalance) {
            transformed = myBalance;
        }
        return transformed;
    }

    function _countOnes(uint256 n) 
        internal 
        pure 
        returns (uint256 count) 
    {
        assembly {
            for { } gt(n, 0) { } {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }
}
