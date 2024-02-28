// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BidTacToe} from "./BidTacToe.sol";
import {MercuryBidTacToeBot} from "./MercuryBidTacToeBot.sol";

contract BidTacToePlayerVersusBot is BidTacToe {
    function commitBid(uint256 hash) public override onlyPlayers {
        super.commitBid(hash);
        // if human player is done, bot will bid and reveal immediately
        if (msg.sender == player1) {
            MercuryBidTacToeBot(player2).bidAndReveal(this);
        }
    }

    function win(address player, uint256 state) internal override {
        gameStates[player] = state;
        emit WinGame(player, state);
        address otherPlayer = getOtherPlayer(player);
        gameStates[otherPlayer] = state + 1;
        emit LoseGame(otherPlayer, state + 1);
        (bool suceed,) = mercuryBidTacToeAddress.call(
            abi.encodeWithSignature("handleBotWinLoss(address,bool)", player1, player == player1)
        );
        require(suceed, "BidTacToePlayerVersusBot: handleBotWinLoss failed");
    }

    function claimTimeoutPenalty() external override onlyPlayers {}
}
