// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrailblazerTournament} from "./TrailblazerTournament.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryBotTournament is TrailblazerTournament {

    uint256 public _planeSupplyCountThisRound;
    uint256 public _botPointsThisRound;
    uint256 public _botPointsToEnd;

    /*//////////////////////////////////////////////////////////////
                            Mint Function
    //////////////////////////////////////////////////////////////*/

    function tournamentMint(address to) external {
        require(_planeSupplyCountThisRound > 0, "MercuryBotTournament: all planes have been minted this round.");
        require(!checkExistingOwnersThisRound(to), "MercuryBotTournament: already minted this round.");
        uint256 tokenId = LibBase.layout().lastTokenID + 1;
        _safeMint(to, tokenId);
        LibBase.layout().lastTokenID++;
        LibBase.layout().aviationLevels[tokenId] = 1;
        LibBase.layout().aviationPoints[tokenId] = 1;
        aviationRounds[tokenId] = _currentRound;
        _planeSupplyCountThisRound -= 1;
    }

    function checkExistingOwnersThisRound(address to) internal view returns (bool) {
        for (uint256 i = lastIndexPerRound[_currentRound - 1] + 1; i <= LibBase.layout().lastTokenID; i++) {
            if (_ownerOf(i) == to) {
                return true;
            }
        }
        return false;
    } 

    function updateBotStatsThisRound(uint256 planeSupplyCountThisRound, uint256 botPointsThisRound, uint256 botPointsToEnd) external {
        LibDiamond.enforceIsContractOwner();
        _planeSupplyCountThisRound = planeSupplyCountThisRound;
        _botPointsThisRound = botPointsThisRound;
        _botPointsToEnd = botPointsToEnd;
    }


    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) override external onlyGameAddresses {
        bool playerWon = loserTokenId == 0;
        uint256 playerTokenId = winnerTokenId + loserTokenId;

        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        uint256 pointsToMove = estimatePointsToMove(playerTokenId, playerTokenId);
        if (playerWon) {
            if (_botPointsThisRound > pointsToMove) {
                sbs.aviationPoints[playerTokenId] += pointsToMove;
                _botPointsThisRound -= pointsToMove;
            } else {
                sbs.aviationPoints[playerTokenId] += _botPointsThisRound;
                _botPointsThisRound = 0;
            }
            emit LibBase.MovePoints(0, playerTokenId, pointsToMove);
            LibBase.pilot().pilotWin(
                _ownerOf(playerTokenId), sbs.aviationLevels[playerTokenId] * pointsToMove, pointsToMove
            );
        } else {
            sbs.aviationPoints[playerTokenId] -= pointsToMove;
            _botPointsThisRound += pointsToMove;
            emit LibBase.MovePoints(playerTokenId, 0, pointsToMove);
            LibBase.pilot().pilotLose(
                _ownerOf(playerTokenId), sbs.aviationLevels[playerTokenId] * pointsToMove, pointsToMove
            );
        }

        updateLevel(playerTokenId);

        if (sbs.aviationPoints[playerTokenId] == 0) {
            burnAviation(playerTokenId);
        }

        if (_botPointsThisRound == 0) {
            _tournamentRoundOver();
        }
    }
}
