// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SkylabBidTacToe } from "./SkylabBidTacToe.sol";
import { BidTacToe } from "./BidTacToe.sol";
import { BidTacToeProxy } from "./BidTacToeProxy.sol";

contract SkylabBidTacToeDeployer {

    function defaultParams() external pure returns (SkylabBidTacToe.GameParams memory) {
        return SkylabBidTacToe.GameParams(3, 3, 3, 100);
    }

    function createGame(SkylabBidTacToe.GameParams memory gameParams, address playerAddress, address skylabBidTacToeAddress) external returns (address) {
        // In general, we only allow odd widths or heights
        require(gameParams.gridWidth == 3 || gameParams.gridWidth == 5, "SkylabBidTacToeParamVerifier: gridWidth incorrect");
        require(gameParams.gridHeight == 3 || gameParams.gridHeight == 5, "SkylabBidTacToeParamVerifier: gridHeight incorrect");
        require(gameParams.lengthToWin >= 3 && gameParams.lengthToWin <= max(gameParams.gridWidth, gameParams.gridHeight), "SkylabBidTacToeParamVerifier: lengthToWin incorrect");
        require(gameParams.initialBalance >= 100 && gameParams.initialBalance <= 10000, "SkylabBidTacToeParamVerifier: initialBalance incorrect");
        BidTacToeProxy bidTacToeProxy = new BidTacToeProxy();
        (bool suceed,) = address(bidTacToeProxy).call(abi.encodeWithSignature("initialize((uint64,uint64,uint64,uint64),address,address)", gameParams, playerAddress, skylabBidTacToeAddress));
        require(suceed, "create game faild");
        return address(bidTacToeProxy);
    }

    function joinGame(address gameAddress, address playerAddress) external {
        BidTacToe existingGame = BidTacToe(gameAddress);
        existingGame.joinGame(playerAddress);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

}