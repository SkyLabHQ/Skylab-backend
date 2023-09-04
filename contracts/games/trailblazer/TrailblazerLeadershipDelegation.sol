// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {TrailblazerTournament} from "../../aviation/TrailblazerTournament.sol";

contract TrailblazerLeadershipDelegation {
    using Strings for uint256;

    TrailblazerTournament private _trailblazerTournament;

    constructor(address trailblazerTournamentAddress) {
        _trailblazerTournament = TrailblazerTournament(trailblazerTournamentAddress);
    }

    function leaderboardInfo(uint256 round, uint256 lastId)
        external
        view
        returns (TrailblazerTournament.LeaderboardInfo[] memory)
    {
        if (round < _trailblazerTournament._currentRound()) {
            return _trailblazerTournament.leaderboardInfo(round);
        } else {
            uint256 startIndex = _trailblazerTournament.lastIndexPerRound(round - 1) + 1;
            uint256 endIndex = lastId;
            TrailblazerTournament.LeaderboardInfo[] memory leaderboardInfos =
                new TrailblazerTournament.LeaderboardInfo[](endIndex - startIndex + 1);

            uint256 index = 0;
            for (uint256 i = startIndex; i <= endIndex; i++) {
                index = i - startIndex;
                leaderboardInfos[index] =
                    TrailblazerTournament.LeaderboardInfo(i, _trailblazerTournament.aviationLevels(i));
            }
            return leaderboardInfos;
        }
    }
}
