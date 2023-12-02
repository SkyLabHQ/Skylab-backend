// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BidTacToe} from "./BidTacToe.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";

// Only works for 3x3
contract MercuryBidTacToeBot {
    uint256[3][8] private winFormations;

    function initialize() external {
        LibDiamond.enforceIsContractOwner();
        winFormations = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
    }

    function bidAndReveal(BidTacToe game) external {
        require(address(game) == msg.sender, "BidTacToeBot: tx.origin is not player1");

        uint256 bid = analyzeBid(game);
        game.commitBid(uint256(keccak256(abi.encodePacked(bid, uint256(0)))));
        game.revealBid(bid, 0);
    }

    function analyzeBid(BidTacToe game) internal view returns (uint256) {
        // 1. Collect data
        address human = game.player1();
        address bot = game.player2();
        address[] memory grid = game.getGrid();
        uint256 currentSelectedGrid = game.currentSelectedGrid();
        uint256 myBalance = game.balances(bot);
        uint256 opponentBalance = game.balances(human);
        uint256 botOccupiedGridCounts = game.occupiedGridCounts(bot);
        uint256 humanOccupiedGridCounts = game.occupiedGridCounts(human);

        // 2. Calculate data that're independent from the bid amount
        grid[currentSelectedGrid] = bot;
        uint256 pp_win;
        uint256 bAR_win;
        uint256 hAR_win;
        (pp_win, bAR_win, hAR_win) =
            computeGridRelatedData(grid, bot, human, botOccupiedGridCounts + 1, humanOccupiedGridCounts);
        // certain win
        if ((pp_win > 1000 || botOccupiedGridCounts + 1 >= 5) && myBalance > opponentBalance) {
            // 2.a Early termination if I can immediately win by connecting 3
            return opponentBalance + 1;
        }
        grid[currentSelectedGrid] = human;
        uint256 pp_lose;
        uint256 bAR_lose;
        uint256 hAR_lose;
        (pp_lose, bAR_lose, hAR_lose) =
            computeGridRelatedData(grid, bot, human, botOccupiedGridCounts, humanOccupiedGridCounts + 1);

        // 3. Calculate data that're based on bid amount
        uint256 optimalBid = 0;
        uint256 bestScore = 0;
        uint256 guessimateOpponentBid = opponentBalance / (5 - humanOccupiedGridCounts);
        if (guessimateOpponentBid == 0) {
            guessimateOpponentBid = 1;
        }
        for (uint256 bid = 0; bid <= myBalance; bid++) {
            // 3.a roughly estimate the win possibility assuming that most players play with basic intelligence
            uint256 win_rate = 1000;
            if (bid <= opponentBalance && bid <= 2 * guessimateOpponentBid) {
                win_rate = 1000 * bid / (2 * guessimateOpponentBid);
            }

            // 3.b win-case: pessimistically assume oppponent bid nothing
            uint256 rp_win = calculateResourcePower(myBalance - bid, opponentBalance, bAR_win, hAR_win);
            // 3.c lose-case: readjust opponent bid so that the loss makes sense
            uint256 adjustedOpponentBid = guessimateOpponentBid;
            if (guessimateOpponentBid < bid) {
                if (bid < opponentBalance) {
                    adjustedOpponentBid = bid;
                } else {
                    adjustedOpponentBid = opponentBalance;
                }
            }
            uint256 rp_lose =
                calculateResourcePower(myBalance - bid, opponentBalance - adjustedOpponentBid, bAR_lose, hAR_lose);

            uint256 ps = pp_win * rp_win * win_rate + pp_lose * rp_lose * (1000 - win_rate);

            if (ps > bestScore) {
                bestScore = ps;
                optimalBid = bid;
            }
        }

        return randomize(optimalBid, myBalance);
    }

    function computeGridRelatedData(
        address[] memory grid,
        address bot,
        address human,
        uint256 botOccupiedGridCounts,
        uint256 humanOccupiedGridCounts
    ) internal view returns (uint256, uint256, uint256) {
        // 1. Gather grid based data
        uint256 botWaysToWin = 0;
        uint256 humanWaysToWin = 0;
        uint256 botCountOf2s = 0;
        uint256 humanCountOf2s = 0;

        uint256 botCountPerLine;
        uint256 humanCountPerLine;
        uint256 pp_overwrite = 12345;
        for (uint256 i = 0; i < 8; i++) {
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
        uint256 totalRemainingGrid = 9 - botOccupiedGridCounts - humanOccupiedGridCounts;
        uint256 botAdjustedRemaining = adjustRemaining(botCountOf2s, 5 - botOccupiedGridCounts, totalRemainingGrid);
        uint256 humanAdjustedRemaining =
            adjustRemaining(humanCountOf2s, 5 - humanOccupiedGridCounts, totalRemainingGrid);

        // 3. Calculate positional power
        uint256 pp = pp_overwrite;
        if (pp == 12345) {
            pp = calculatePositionalPower(botWaysToWin, humanWaysToWin);
        }

        return (pp, botAdjustedRemaining, humanAdjustedRemaining);
    }

    function adjustRemaining(uint256 co2, uint256 baseRemaining, uint256 totalRemainingGrid)
        internal
        pure
        returns (uint256)
    {
        if (totalRemainingGrid == 0 || baseRemaining == 0) {
            return 0;
        }
        return 100 * (baseRemaining * totalRemainingGrid - (baseRemaining - 1) * co2) / totalRemainingGrid;
    }

    function calculatePositionalPower(uint256 botWaysToWin, uint256 humanWaysToWin) internal pure returns (uint256) {
        // plus 1 represents winning by occupying more
        return 1000 * (botWaysToWin + 1) / (botWaysToWin + humanWaysToWin + 2);
    }

    function calculateResourcePower(
        uint256 myBalance,
        uint256 opponentBalance,
        uint256 adjustedMyRemaining,
        uint256 adjustedOpponentRemaining
    ) public pure returns (uint256) {
        if (adjustedMyRemaining == 0) {
            return 1000;
        }
        if (adjustedOpponentRemaining == 0) {
            return 0;
        }

        // account for 100 scaling on remaining
        uint256 myPerPieceResourcePower = 1000 * 100 * myBalance / adjustedMyRemaining;
        uint256 opponentPerPieceResourcePower = 1000 * 100 * opponentBalance / adjustedOpponentRemaining;

        if (opponentPerPieceResourcePower == 0) {
            return 1000;
        }

        uint256 final_score = 500 * myPerPieceResourcePower / opponentPerPieceResourcePower;
        if (final_score > 1000) {
            final_score = 1000;
        }
        return final_score;
        // return 1000 * myPerPieceResourcePower / (myPerPieceResourcePower + opponentPerPieceResourcePower);
    }

    function randomize(uint256 bid, uint256 myBalance) internal view returns (uint256) {
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

    function lineOwnership(address[] memory grid, address player1, address player2, uint256[3] memory indexes)
        internal
        pure
        returns (uint256, uint256)
    {
        return (
            gridOwnership(grid, player1, indexes[0]) + gridOwnership(grid, player1, indexes[1])
                + gridOwnership(grid, player1, indexes[2]),
            gridOwnership(grid, player2, indexes[0]) + gridOwnership(grid, player2, indexes[1])
                + gridOwnership(grid, player2, indexes[2])
        );
    }

    function gridOwnership(address[] memory grid, address player, uint256 index) internal pure returns (uint256) {
        if (grid[index] == player) {
            return 1;
        }

        return 0;
    }

    function _countOnes(uint256 n) internal pure returns (uint256 count) {
        assembly {
            for {} gt(n, 0) {} {
                n := and(n, sub(n, 1))
                count := add(count, 1)
            }
        }
    }
}
