// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BidTacToe} from "./BidTacToe.sol";

// Only works for 3x3
contract MercuryBidTacToeBot {
    uint[3][8] private winFormations = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];

    function bidAndReveal(BidTacToe game)
        external
    {
        require(address(game) == msg.sender, "BidTacToeBot: tx.origin is not player1");

        uint bid = analyzeBid(game);
        game.commitBid(uint256(keccak256(abi.encodePacked(bid, uint(0)))));
        game.revealBid(bid, 0);
    }

    function analyzeBid(BidTacToe game) internal view returns (uint) {
        // 1. Collect data
        address human = game.player1();
        address bot = game.player2();
        address[] memory grid = game.getGrid();
        uint currentSelectedGrid = game.currentSelectedGrid();
        uint myBalance = game.balances(bot);
        uint opponentBalance = game.balances(human);
        uint botOccupiedGridCounts = game.occupiedGridCounts(bot);
        uint humanOccupiedGridCounts = game.occupiedGridCounts(human);

        // 2. Calculate data that're independent from the bid amount
        grid[currentSelectedGrid] = bot;
        uint pp_win;
        uint bAR_win;
        uint hAR_win;
        (pp_win, bAR_win, hAR_win) = computeGridRelatedData(grid, bot, human, botOccupiedGridCounts + 1, humanOccupiedGridCounts);
        // certain win
        if ((pp_win > 1000 || botOccupiedGridCounts + 1 >= 5) && myBalance > opponentBalance) {
            // 2.a Early termination if I can immediately win by connecting 3
            return opponentBalance + 1;
        }
        grid[currentSelectedGrid] = human;
        uint pp_lose;
        uint bAR_lose;
        uint hAR_lose;
        (pp_lose, bAR_lose, hAR_lose) = computeGridRelatedData(grid, bot, human, botOccupiedGridCounts, humanOccupiedGridCounts + 1);

        // 3. Calculate data that're based on bid amount
        uint optimalBid = 0;
        uint bestScore = 0;
        uint guessimateOpponentBid = opponentBalance / (5 - humanOccupiedGridCounts);
        if (guessimateOpponentBid == 0) {
            guessimateOpponentBid = 1;
        }
        for (uint bid = 0; bid <= myBalance; bid++) {
            // 3.a roughly estimate the win possibility assuming that most players play with basic intelligence
            uint win_rate = 1000;
            if (bid <= opponentBalance && bid <= 2 * guessimateOpponentBid) {
                win_rate = 1000 * bid / (2 * guessimateOpponentBid);
            }

            // 3.b win-case: pessimistically assume oppponent bid nothing
            uint rp_win = calculateResourcePower(myBalance - bid, opponentBalance, bAR_win, hAR_win);
            // 3.c lose-case: readjust opponent bid so that the loss makes sense
            uint adjustedOpponentBid = guessimateOpponentBid;
            if (guessimateOpponentBid < bid) {
                if (bid < opponentBalance) {
                    adjustedOpponentBid = bid;
                } else {
                    adjustedOpponentBid = opponentBalance;
                }
            }
            uint rp_lose = calculateResourcePower(myBalance - bid, opponentBalance - adjustedOpponentBid, bAR_lose, hAR_lose);
            
            uint ps = pp_win * rp_win * win_rate + pp_lose * rp_lose * (1000 - win_rate);

            if (ps > bestScore) {
                bestScore = ps;
                optimalBid = bid;
            }
        }

        return randomize(optimalBid, myBalance);
    }

    function computeGridRelatedData(address[] memory grid, address bot, address human, uint botOccupiedGridCounts, uint humanOccupiedGridCounts) internal view returns (uint, uint, uint) {
        // 1. Gather grid based data
        uint botWaysToWin = 0;
        uint humanWaysToWin = 0;
        uint botCountOf2s = 0;
        uint humanCountOf2s = 0;

        uint botCountPerLine;
        uint humanCountPerLine;
        uint pp_overwrite = 12345;
        for (uint i = 0; i < 8; i++) {
            (botCountPerLine, humanCountPerLine) = lineOwnership(grid, bot, human, winFormations[i]);
            if (botCountPerLine == 3) {
                pp_overwrite = 1001;
            }
            if (humanCountPerLine == 3) {
                pp_overwrite = 0;
            }

            if (botCountPerLine == 0 && humanCountPerLine == 0) {
                botWaysToWin += 1;
                humanWaysToWin += 1;
            } else if (botCountPerLine == 0 && humanCountPerLine > 0) {
                humanWaysToWin += 1;
                if (humanCountPerLine == 2) {
                    humanCountOf2s += 1;
                }
            } else if (botCountPerLine > 0 && humanCountPerLine == 0) {
                botWaysToWin += 1;
                if (botCountPerLine == 2) {
                    botCountOf2s += 1;
                }
            }
        }

        // 2. Calculate adjusted remaining count
        uint totalRemainingGrid = 9 - botOccupiedGridCounts - humanOccupiedGridCounts;
        uint botAdjustedRemaining = adjustRemaining(botCountOf2s, 5 - botOccupiedGridCounts, totalRemainingGrid);
        uint humanAdjustedRemaining = adjustRemaining(humanCountOf2s, 5 - humanOccupiedGridCounts, totalRemainingGrid);

        // 3. Calculate positional power
        uint pp = pp_overwrite;
        if (pp == 12345) {
            pp = calculatePositionalPower(botWaysToWin, humanWaysToWin);
        }

        return (pp, botAdjustedRemaining, humanAdjustedRemaining);
    }

    function adjustRemaining(uint co2, uint baseRemaining, uint totalRemainingGrid) internal pure returns (uint) {
        if (totalRemainingGrid == 0 || baseRemaining == 0) {
            return 0;
        }
        return 100 * (baseRemaining * totalRemainingGrid - (baseRemaining - 1) * co2)  / totalRemainingGrid;
    }

    function calculatePositionalPower(uint botWaysToWin, uint humanWaysToWin) internal pure returns (uint) {
        // plus 1 represents winning by occupying more
        return 1000 * (botWaysToWin + 1) / (botWaysToWin + humanWaysToWin + 2);
    }

    function calculateResourcePower(uint myBalance, uint opponentBalance, uint adjustedMyRemaining, uint adjustedOpponentRemaining) public pure returns (uint) {
        if (adjustedMyRemaining == 0) {
            return 1000;
        }
        if (adjustedOpponentRemaining == 0) {
            return 0;
        }

        // account for 100 scaling on remaining
        uint myPerPieceResourcePower = 1000 * 100 * myBalance / adjustedMyRemaining; 
        uint opponentPerPieceResourcePower = 1000 * 100 * opponentBalance / adjustedOpponentRemaining;

        if (opponentPerPieceResourcePower == 0) {
            return 1000;
        }

        uint final_score = 500 * myPerPieceResourcePower / opponentPerPieceResourcePower;
        if (final_score > 1000) {
            final_score = 1000;
        }
        return final_score;
        // return 1000 * myPerPieceResourcePower / (myPerPieceResourcePower + opponentPerPieceResourcePower);
    }

    function randomize(uint bid, uint myBalance) internal view returns (uint) {
        // get a random number around 128, standard deviation 8
        uint256 result = _countOnes(uint256(keccak256(abi.encodePacked(bid + block.timestamp))));
        // transform it to a number around bid * 100; lower bound it at -4*stdev
        uint256 transformed = 0;
        if (result <= 128) {
            // randomize down to 0
            if (result <= 96) result = 0;
            else result -= 96;
            transformed = 100 * result * bid / 32;
        } else {
            // randomize up to 2*bid (pessimistic)
            result = result - 128;
            if (result > 32) result = 32;
            transformed = 100 * result * bid / 32 + 100 * bid;
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


    function lineOwnership(address[] memory grid, address player1, address player2, uint[3] memory indexes) internal pure returns (uint, uint) {
        return (gridOwnership(grid, player1, indexes[0]) + gridOwnership(grid, player1, indexes[1]) + gridOwnership(grid, player1, indexes[2]), gridOwnership(grid, player2, indexes[0]) + gridOwnership(grid, player2, indexes[1]) + gridOwnership(grid, player2, indexes[2]));
    }

    function gridOwnership(address[] memory grid, address player, uint index) internal pure returns (uint) {
        if (grid[index] == player) {
            return 1;
        }
            
        return 0;
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
