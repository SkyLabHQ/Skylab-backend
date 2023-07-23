// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { TrailblazerTournament } from "./TrailblazerTournament.sol";

contract TrailblazerLeadershipDelegation {
    using Strings for uint;

    TrailblazerTournament private _trailblazerTournament;

    constructor(address trailblazerTournamentAddress) {
        _trailblazerTournament = TrailblazerTournament(trailblazerTournamentAddress);
    }

    function leaderboardInfo(uint round, uint lastId) external view returns (TrailblazerTournament.LeaderboardInfo[] memory) {
        if (round < _trailblazerTournament._currentRound()) {
            return _trailblazerTournament.leaderboardInfo(round);
        } else {
            uint startIndex = _trailblazerTournament._lastIndexPerRound(round - 1) + 1;
            uint endIndex = lastId;
            TrailblazerTournament.LeaderboardInfo[] memory leaderboardInfos = new TrailblazerTournament.LeaderboardInfo[](endIndex - startIndex + 1);

            uint index = 0;
            for (uint i = startIndex; i <= endIndex; i++) {
                index = i - startIndex;
                leaderboardInfos[index] = TrailblazerTournament.LeaderboardInfo(i, _trailblazerTournament._aviationLevels(i));
            }
            return leaderboardInfos;
        }
    }
}
