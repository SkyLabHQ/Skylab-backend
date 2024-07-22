// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";
import {MercuryBidTacToe} from "../games/bidtactoe/MercuryBidTacToe.sol";
import {BidTacToe} from "../games/bidtactoe/BidTacToe.sol";

contract MercuryStreamerAviation is MercuryBase {
    MercuryBidTacToe public mercuryBidTacToe;
    address[] public players;
    mapping(address => address[]) public gameAddresses;
    mapping(address => bool) public playerExist;

    function initStreamAviation(MercuryBidTacToe mercuryBidTacToe_) public {
        LibDiamond.enforceIsContractOwner();
        mercuryBidTacToe = mercuryBidTacToe_;
    }

    function streamerMint(address to, uint256 points) public {
        LibDiamond.enforceIsContractOwner();
        uint256 tokenId = baseMint(to);
        LibBase.layout().aviationPoints[tokenId] = points;
        players.push(to);
        playerExist[to] = true;
    }

    function matchmaking(address player1, address player2) public {
        require(playerExist[player1] && playerExist[player2], "MercuryStreamerAviation: players not exists");
        address gameAddress = mercuryBidTacToe.streamerMatch(player1, player2);
        gameAddresses[player1].push(gameAddress);
        gameAddresses[player2].push(gameAddress);
        delete playerExist[player1];
        delete playerExist[player2];
        for(uint i = 0; i < players.length; i++) {
            if (players[i] == player1 || players[i] == player2) {
                delete players[i];
            }
        }
    }

    function GameResult(address player) public view returns(uint256[] memory) {
        address[] memory games = gameAddresses[player];
        uint256[] memory gameState = new uint256[](games.length);
        for (uint256 i = 0; i < games.length; i++) {
            gameState[i] = BidTacToe(games[i]).gameStates(player);
        }
        return gameState;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        return "";
    }
}