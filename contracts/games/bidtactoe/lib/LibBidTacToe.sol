// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBidTacToe} from "../MercuryBidTacToe.sol";
import {BidTacToe} from "../BidTacToe.sol";
import {BidTacToeProxy} from "../BidTacToeProxy.sol";

library LibBidTacToe {
    function defaultParams() internal pure returns (MercuryBidTacToe.GameParams memory) {
        return MercuryBidTacToe.GameParams(3, 3, 3, 100);
    }

    function createGame(
        MercuryBidTacToe.GameParams memory gameParams,
        address playerAddress,
        address mercuryBidTacToeAddress,
        address collection
    ) internal returns (address) {
        // In general, we only allow odd widths or heights
        require(
            gameParams.gridWidth == 3 || gameParams.gridWidth == 5, "MercuryBidTacToeParamVerifier: gridWidth incorrect"
        );
        require(
            gameParams.gridHeight == 3 || gameParams.gridHeight == 5,
            "MercuryBidTacToeParamVerifier: gridHeight incorrect"
        );
        require(
            gameParams.lengthToWin >= 3 && gameParams.lengthToWin <= max(gameParams.gridWidth, gameParams.gridHeight),
            "MercuryBidTacToeParamVerifier: lengthToWin incorrect"
        );
        require(
            gameParams.initialBalance >= 100 && gameParams.initialBalance <= 10000,
            "MercuryBidTacToeParamVerifier: initialBalance incorrect"
        );
        BidTacToeProxy bidTacToeProxy = new BidTacToeProxy();
        (bool suceed,) = address(bidTacToeProxy).call(
            abi.encodeWithSignature(
                "initialize((uint64,uint64,uint64,uint64),address,address,address)",
                gameParams,
                playerAddress,
                mercuryBidTacToeAddress,
                collection
            )
        );
        require(suceed, "create game faild");
        return address(bidTacToeProxy);
    }

    function joinGame(address gameAddress, address playerAddress) internal {
        BidTacToe existingGame = BidTacToe(gameAddress);
        existingGame.joinGame(playerAddress);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
