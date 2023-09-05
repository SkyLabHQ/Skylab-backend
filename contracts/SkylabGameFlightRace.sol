// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoseidonT3, PoseidonT4} from "./poseidon.sol";
import {GameboardTraverseVerifier} from "./GameboardTraverseVerifier.sol";
import {ComputeHashPathDataVerifier} from "./ComputeHashPathDataVerifier.sol";
import {MapHashes} from "./MapHashes.sol";
import {SkylabGameBase} from "./SkylabGameBase.sol";

contract SkylabGameFlightRace is SkylabGameBase {
    struct GameTank {
        uint256 fuel;
        uint256 battery;
    }

    struct CommittedHash {
        bool first;
        uint256 seed_hash;
        uint256 time_hash;
        uint256 path_hash;
        uint256 used_resources_hash;
    }

    struct RevealedOpponentData {
        uint256 final_time;
        uint256[101] path;
        uint256[101] used_resources;
    }

    GameboardTraverseVerifier private _gameboardTraverseVerifier;
    ComputeHashPathDataVerifier private _computeHashPathDataVerifier;
    MapHashes private _mapHashes;

    // ====================
    // Gameplay data
    // ====================
    mapping(uint256 => uint256) private matchingQueues;
    mapping(uint256 => uint256) public gameState;
    mapping(uint256 => GameTank) public gameTank;

    // Static values
    uint256 constant searchOpponentTimeout = 300;
    uint256 constant getMapTimeout = 900;
    uint256 constant commitTimeout = 300;

    /*
    *   State 1: queueing or found opponent; Next: getMap within timeout
    */
    // id => id
    mapping(uint256 => uint256) public matchedAviationIDs;
    // id => timeout
    mapping(uint256 => uint256) public timeout;

    /*
    *   State 2: map found; Next: commit data within timeout
    */
    // id => id
    mapping(uint256 => uint256) public mapId;

    /*
    *   State 3: data committed; Next: reveal data within timeout
    */
    // id => CommittedHash
    mapping(uint256 => CommittedHash) public committedHash;

    /*
    *   State 4: data revealed or winner determined; Next: set winner/loser state and clean up
    */
    // id => final time
    mapping(uint256 => RevealedOpponentData) internal revealedOpponentData;

    /*
    *   State 5: winner state
    *   State 6: loser state
    *   State 7: escape state
    */

    constructor(
        address skylabBaseAddress,
        address gameboardTraverseVerifierAddress,
        address computeHashPathDataVerifierAddress,
        address mapHashesAddress
    ) SkylabGameBase(skylabBaseAddress) {
        _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
        _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
        _mapHashes = MapHashes(mapHashesAddress);
    }

    function loadFuelBatteryToGameTank(uint256 tokenId, uint256 fuel, uint256 battery) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "SkylabGameFlightRace: incorrect gameState");

        // PLAYTEST DISABLE uint tokenLevel = _skylabBase._aviationLevels(tokenId);
        // PLAYTEST DISABLE uint totalResourceCap = 50 * 2 ** (tokenLevel - 1);
        // PLAYTEST DISABLE require(gameTank[tokenId].fuel + fuel + gameTank[tokenId].battery + battery <= totalResourceCap, "SkylabGameFlightRace: resources exceeds resource cap");

        uint256[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint256[] memory resourceAmounts = new uint[](2);
        resourceAmounts[0] = fuel;
        resourceAmounts[1] = battery;
        _skylabBase.requestResourcesForGame(_skylabBase.ownerOf(tokenId), address(this), ids, resourceAmounts);
        gameTank[tokenId].fuel += fuel;
        gameTank[tokenId].battery += battery;
    }

    // ====================
    // Aviation Collision
    // ====================

    function searchOpponent(uint256 tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "SkylabGameFlightRace: incorrect gameState");
        require(!_skylabBase.isAviationLocked(tokenId), "SkylabGameFlightRace: token is locked");

        _skylabBase.aviationLock(tokenId);

        uint256 currentQueue = matchingQueues[_skylabBase.aviationLevels(tokenId)];

        if (currentQueue == 0) {
            matchingQueues[_skylabBase.aviationLevels(tokenId)] = tokenId;
        } else {
            require(
                _skylabBase.ownerOf(tokenId) != _skylabBase.ownerOf(currentQueue), "SkylabGameFlightRace: no in-fight"
            );
            matchedAviationIDs[tokenId] = currentQueue;
            matchedAviationIDs[currentQueue] = tokenId;
            timeout[tokenId] = block.timestamp + searchOpponentTimeout;
            timeout[currentQueue] = block.timestamp + searchOpponentTimeout;
            matchingQueues[_skylabBase.aviationLevels(tokenId)] = 0;
        }
        gameState[tokenId] = 1;
    }

    function getMap(uint256 tokenId) external returns (uint256) {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");

        uint256 mapIdGenerated;
        if (mapId[matchedAviationIDs[tokenId]] != 0) {
            mapIdGenerated = mapId[matchedAviationIDs[tokenId]];
        } else if (tokenId < matchedAviationIDs[tokenId]) {
            mapIdGenerated = _mapHashes.getMapID(
                _skylabBase.aviationLevels(tokenId),
                uint256(
                    PoseidonT4.poseidon(
                        [bytes32(block.timestamp), bytes32(tokenId), bytes32(matchedAviationIDs[tokenId])]
                    )
                )
            );
        } else {
            mapIdGenerated = _mapHashes.getMapID(
                _skylabBase.aviationLevels(tokenId),
                uint256(
                    PoseidonT4.poseidon(
                        [bytes32(block.timestamp), bytes32(matchedAviationIDs[tokenId]), bytes32(tokenId)]
                    )
                )
            );
        }
        timeout[tokenId] = block.timestamp + getMapTimeout;
        mapId[tokenId] = mapIdGenerated;
        gameState[tokenId] = 2;
        return mapIdGenerated;
    }

    function commitPath(
        uint256 tokenId,
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[9] memory input
    ) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        // seed_hash, map_hash, start_fuel_confirm, start_battery_confirm, final_time_hash, path_hash, used_resources_hash, level_scaler, c1
        require(gameState[tokenId] == 2, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(_gameboardTraverseVerifier.verifyProof(a, b, c, input), "SkylabGameFlightRace: incorrect proof");
        require(
            _mapHashes.verifyMap(mapId[tokenId], _skylabBase.aviationLevels(tokenId), input[1]),
            "SkylabGameFlightRace: map hash verification failed"
        );
        require(gameTank[tokenId].fuel == input[2], "SkylabGameFlightRace: incorrect starting fuel");
        require(gameTank[tokenId].battery == input[3], "SkylabGameFlightRace: incorrect starting battery");
        require(
            2 ** (_skylabBase.aviationLevels(tokenId) - 1) == input[7], "SkylabGameFlightRace: incorrect level scaler"
        );
        require(
            _mapHashes.verifyMapC1(_skylabBase.aviationLevels(tokenId), input[8]), "SkylabGameFlightRace: incorrect c1"
        );

        // verify
        committedHash[tokenId] =
            CommittedHash(gameState[matchedAviationIDs[tokenId]] != 3, input[0], input[4], input[5], input[6]);
        gameState[tokenId] = 3;
        // temporarily reset timeout
        timeout[tokenId] = 0;

        if (gameState[matchedAviationIDs[tokenId]] == 3) {
            timeout[tokenId] = block.timestamp + commitTimeout;
            timeout[matchedAviationIDs[tokenId]] = block.timestamp + commitTimeout;
        }
    }

    function revealPath(
        uint256 tokenId,
        uint256 seed,
        uint256 time,
        uint256[2] memory pathA,
        uint256[2][2] memory pathB,
        uint256[2] memory pathC,
        uint256[101] memory pathInput,
        uint256[2] memory usedResourcesA,
        uint256[2][2] memory usedResourcesB,
        uint256[2] memory usedResourcesC,
        uint256[101] memory usedResourcesInput
    ) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 3, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(gameState[matchedAviationIDs[tokenId]] >= 3, "SkylabGameFlightRace: incorrect opponent gameState");
        require(committedHash[tokenId].seed_hash == poseidon(seed, seed), "SkylabGameFlightRace: incorrect seed hash");
        require(committedHash[tokenId].time_hash == poseidon(time, seed), "SkylabGameFlightRace: incorrect time hash");
        require(committedHash[tokenId].path_hash == pathInput[0], "SkylabGameFlightRace: incorrect path hash");
        require(
            committedHash[tokenId].used_resources_hash == usedResourcesInput[0],
            "SkylabGameFlightRace: incorrect used resources hash"
        );
        require(
            _computeHashPathDataVerifier.verifyProof(pathA, pathB, pathC, pathInput),
            "SkylabGameFlightRace: incorrect path proof"
        );
        require(
            _computeHashPathDataVerifier.verifyProof(usedResourcesA, usedResourcesB, usedResourcesC, usedResourcesInput),
            "SkylabGameFlightRace: incorrect used resources hash"
        );

        revealedOpponentData[matchedAviationIDs[tokenId]] = RevealedOpponentData(time, pathInput, usedResourcesInput);
        gameState[tokenId] = 4;
        // temporarily reset timeout
        timeout[tokenId] = 0;

        if (gameState[matchedAviationIDs[tokenId]] == 4) {
            if (time < revealedOpponentData[tokenId].final_time) {
                win(tokenId);
                lose(matchedAviationIDs[tokenId]);
            } else if (time == revealedOpponentData[tokenId].final_time && committedHash[tokenId].first) {
                win(tokenId);
                lose(matchedAviationIDs[tokenId]);
            } else {
                win(matchedAviationIDs[tokenId]);
                lose(tokenId);
            }
        }
    }

    function postGameCleanUp(uint256 tokenId) external {
        require(
            isApprovedForGame(tokenId) || _skylabBase.ownerOf(tokenId) == address(0),
            "SkylabGameFlightRace: caller is not token owner or approved"
        );
        require(
            gameState[tokenId] == 5 || gameState[tokenId] == 6 || gameState[tokenId] == 7,
            "SkylabGameFlightRace: incorrect gameState"
        );

        reset(tokenId, gameState[tokenId] == 5 || gameState[tokenId] == 6);
    }

    function claimTimeoutPenalty(uint256 tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] > 0, "SkylabGameFlightRace: incorrect gameState");
        require(gameState[tokenId] < 5, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");
        require(timeout[matchedAviationIDs[tokenId]] > 0, "SkylabGameFlightRace: timeout isn't defined");
        require(block.timestamp > timeout[matchedAviationIDs[tokenId]], "SkylabGameFlightRace: timeout didn't pass yet");

        win(tokenId);
        lose(matchedAviationIDs[tokenId]);
    }

    function withdrawFromQueue(uint256 tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] == 0, "SkylabGameFlightRace: already has matched opponent");

        matchingQueues[_skylabBase.aviationLevels(tokenId)] = 0;

        reset(tokenId, false);
    }

    function retreat(uint256 tokenId) external {
        require(isApprovedForGame(tokenId), "SkylabGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1 || gameState[tokenId] == 2, "SkylabGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "SkylabGameFlightRace: no matched opponent");

        escape(tokenId);
        win(matchedAviationIDs[tokenId]);
    }

    function reset(uint256 tokenId, bool clearTank) internal {
        _skylabBase.aviationUnlock(tokenId);
        matchedAviationIDs[tokenId] = 0;
        timeout[tokenId] = 0;
        mapId[tokenId] = 0;
        delete committedHash[tokenId];
        delete revealedOpponentData[tokenId];
        if (!clearTank) {
            uint256[] memory ids = new uint[](2);
            ids[0] = 0;
            ids[1] = 1;
            uint256[] memory resourceAmounts = new uint[](2);
            resourceAmounts[0] = gameTank[tokenId].fuel;
            resourceAmounts[1] = gameTank[tokenId].battery;
            _skylabBase.refundResourcesFromGame(address(this), _skylabBase.ownerOf(tokenId), ids, resourceAmounts);
        }
        delete gameTank[tokenId];

        /*
        if (gameState[tokenId] == 5) {
            if (_skylabBase._aviationLevels(tokenId) == 1) {
                _skylabBase.aviationGainCounter(tokenId);
            }
            _skylabBase.aviationGainCounter(tokenId);
        } else if (gameState[tokenId] == 6 || gameState[tokenId] == 7) {
            _skylabBase.aviationLevelDown(tokenId, 1);
        }
        */
        gameState[tokenId] = 0;
    }

    function poseidon(uint256 input_0, uint256 input_1) private pure returns (uint256) {
        return uint256(PoseidonT3.poseidon([bytes32(input_0), bytes32(input_1)]));
    }

    function win(uint256 tokenId) private {
        gameState[tokenId] = 5;
    }

    function lose(uint256 tokenId) private {
        gameState[tokenId] = 6;
    }

    function escape(uint256 tokenId) private {
        gameState[tokenId] = 7;
    }

    // Utils
    function getOpponentFinalTime(uint256 tokenId) external view returns (uint256) {
        return revealedOpponentData[tokenId].final_time;
    }

    function getOpponentPath(uint256 tokenId) external view returns (uint256[101] memory) {
        return revealedOpponentData[tokenId].path;
    }

    function getOpponentUsedResources(uint256 tokenId) external view returns (uint256[101] memory) {
        return revealedOpponentData[tokenId].used_resources;
    }

    // Admin
    function refreshAddresses(
        address gameboardTraverseVerifierAddress,
        address computeHashPathDataVerifierAddress,
        address mapHashesAddress
    ) external onlyOwner {
        _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
        _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
        _mapHashes = MapHashes(mapHashesAddress);
    }
}
