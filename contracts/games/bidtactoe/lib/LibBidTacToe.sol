// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBidTacToe} from "../MercuryBidTacToe.sol";
import {BidTacToe} from "../BidTacToe.sol";
import {BidTacToeProxy} from "../BidTacToeProxy.sol";

library LibBidTacToe {
    function defaultParams() internal pure returns (MercuryBidTacToe.GameParams memory) {
        return MercuryBidTacToe.GameParams(3, 3, 3, 100, 1, 0, false, 90);
    }

    function defaultBotParams() internal pure returns (MercuryBidTacToe.GameParams memory) {
        return MercuryBidTacToe.GameParams(3, 3, 3, 100, 1, 0, true, 90);
    }

    function createGame(
        MercuryBidTacToe.GameParams memory gameParams,
        address playerAddress,
        address mercuryBidTacToeAddress,
        address privateLobbyAddress
    ) internal returns (address) {
        // In general, we only allow odd widths or heights
        require(gameParams.gridWidth == 3, "MercuryBidTacToeParamVerifier: gridWidth incorrect");
        require(gameParams.gridHeight == 3, "MercuryBidTacToeParamVerifier: gridHeight incorrect");
        require(
            gameParams.lengthToWin >= 3 && gameParams.lengthToWin <= max(gameParams.gridWidth, gameParams.gridHeight),
            "MercuryBidTacToeParamVerifier: lengthToWin incorrect"
        );
        require(gameParams.initialBalance >= 100, "MercuryBidTacToeParamVerifier: initialBalance incorrect");
        require(
            gameParams.gridMaxSelectionCount >= 1 && gameParams.gridMaxSelectionCount <= 2,
            "MercuryBidTacToeParamVerifier: gridMaxSelectionCount incorrect"
        );
        require(
            gameParams.gridSelectionStrategy >= 0 && gameParams.gridSelectionStrategy <= 2,
            "MercuryBidTacToeParamVerifier: gridSelectionStrategy incorrect"
        );
        BidTacToeProxy bidTacToeProxy = new BidTacToeProxy(gameParams.isBot);
        (bool suceed,) = address(bidTacToeProxy).call(
            abi.encodeWithSignature(
                "initialize((uint64,uint64,uint64,uint64,uint128,uint128,bool,uint256),address,address,address)",
                gameParams,
                playerAddress,
                mercuryBidTacToeAddress,
                privateLobbyAddress
            )
        );
        require(suceed, "create game faild");
        return address(bidTacToeProxy);
    }

    function joinGame(address gameAddress, address playerAddress) internal {
        BidTacToe existingGame = BidTacToe(gameAddress);
        existingGame.joinGame(playerAddress);
    }

    function getPlayer1(address gameAddress) internal view returns (address) {
        BidTacToe existingGame = BidTacToe(gameAddress);
        return existingGame.player1();
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}
