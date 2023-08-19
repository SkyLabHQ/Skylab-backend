// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SkylabBidTacToe } from "./SkylabBidTacToe.sol";


contract SkylabBidTacToeParamVerifier {

    function defaultParams() external pure returns (SkylabBidTacToe.GameParams memory) {
        return SkylabBidTacToe.GameParams(3, 3, 3, 100);
    }

    function verify(SkylabBidTacToe.GameParams memory gameParams) external pure {
        // In general, we only allow odd widths or heights
        require(gameParams.gridWidth == 3 || gameParams.gridWidth == 5, "SkylabBidTacToeParamVerifier: gridWidth incorrect");
        require(gameParams.gridHeight == 3 || gameParams.gridHeight == 5, "SkylabBidTacToeParamVerifier: gridHeight incorrect");
        require(gameParams.lengthToWin >= 3 && gameParams.lengthToWin <= max(gameParams.gridWidth, gameParams.gridHeight), "SkylabBidTacToeParamVerifier: lengthToWin incorrect");
        require(gameParams.initialBalance >= 100 && gameParams.initialBalance <= 10000, "SkylabBidTacToeParamVerifier: initialBalance incorrect");
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

}