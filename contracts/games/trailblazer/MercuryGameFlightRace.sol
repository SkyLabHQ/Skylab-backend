// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoseidonT3, PoseidonT4} from "../../libraries/poseidon.sol";
import {GameboardTraverseVerifier} from "./GameboardTraverseVerifier.sol";
import {ComputeHashPathDataVerifier} from "./ComputeHashPathDataVerifier.sol";
import {MapHashes} from "./MapHashes.sol";
import {MercuryGameBase} from "../base/MercuryGameBase.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {MercuryBase} from "../../aviation/base/MercuryBase.sol";

contract MercuryGameFlightRace is MercuryGameBase {
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

    // constructor(
    //     address mercuryBaseAddress,
    //     address gameboardTraverseVerifierAddress,
    //     address computeHashPathDataVerifierAddress,
    //     address mapHashesAddress
    // ) MercuryGameBase(mercuryBaseAddress) {
    //     _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
    //     _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
    //     _mapHashes = MapHashes(mapHashesAddress);
    // }

    function loadFuelBatteryToGameTank(uint256 tokenId, uint256 fuel, uint256 battery, MercuryBase collection)
        external
    {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "MercuryGameFlightRace: incorrect gameState");

        // PLAYTEST DISABLE uint tokenLevel = collection._aviationLevels(tokenId);
        // PLAYTEST DISABLE uint totalResourceCap = 50 * 2 ** (tokenLevel - 1);
        // PLAYTEST DISABLE require(gameTank[tokenId].fuel + fuel + gameTank[tokenId].battery + battery <= totalResourceCap, "MercuryGameFlightRace: resources exceeds resource cap");

        uint256[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint256[] memory resourceAmounts = new uint[](2);
        resourceAmounts[0] = fuel;
        resourceAmounts[1] = battery;
        collection.requestResourcesForGame(collection.ownerOf(tokenId), address(this), ids, resourceAmounts);
        gameTank[tokenId].fuel += fuel;
        gameTank[tokenId].battery += battery;
    }

    // ====================
    // Aviation Collision
    // ====================

    function searchOpponent(uint256 tokenId, MercuryBase collection) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 0, "MercuryGameFlightRace: incorrect gameState");
        require(!collection.isAviationLocked(tokenId), "MercuryGameFlightRace: token is locked");

        collection.aviationLock(tokenId);

        uint256 currentQueue = matchingQueues[collection.aviationLevels(tokenId)];

        if (currentQueue == 0) {
            matchingQueues[collection.aviationLevels(tokenId)] = tokenId;
        } else {
            require(
                collection.ownerOf(tokenId) != collection.ownerOf(currentQueue), "MercuryGameFlightRace: no in-fight"
            );
            matchedAviationIDs[tokenId] = currentQueue;
            matchedAviationIDs[currentQueue] = tokenId;
            timeout[tokenId] = block.timestamp + searchOpponentTimeout;
            timeout[currentQueue] = block.timestamp + searchOpponentTimeout;
            matchingQueues[collection.aviationLevels(tokenId)] = 0;
        }
        gameState[tokenId] = 1;
    }

    function getMap(uint256 tokenId, MercuryBase collection) external returns (uint256) {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "MercuryGameFlightRace: no matched opponent");

        uint256 mapIdGenerated;
        if (mapId[matchedAviationIDs[tokenId]] != 0) {
            mapIdGenerated = mapId[matchedAviationIDs[tokenId]];
        } else if (tokenId < matchedAviationIDs[tokenId]) {
            mapIdGenerated = _mapHashes.getMapID(
                collection.aviationLevels(tokenId),
                uint256(
                    PoseidonT4.poseidon(
                        [bytes32(block.timestamp), bytes32(tokenId), bytes32(matchedAviationIDs[tokenId])]
                    )
                )
            );
        } else {
            mapIdGenerated = _mapHashes.getMapID(
                collection.aviationLevels(tokenId),
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
        uint256[9] memory input,
        MercuryBase collection
    ) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        // seed_hash, map_hash, start_fuel_confirm, start_battery_confirm, final_time_hash, path_hash, used_resources_hash, level_scaler, c1
        require(gameState[tokenId] == 2, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "MercuryGameFlightRace: no matched opponent");
        require(_gameboardTraverseVerifier.verifyProof(a, b, c, input), "MercuryGameFlightRace: incorrect proof");
        require(
            _mapHashes.verifyMap(mapId[tokenId], collection.aviationLevels(tokenId), input[1]),
            "MercuryGameFlightRace: map hash verification failed"
        );
        require(gameTank[tokenId].fuel == input[2], "MercuryGameFlightRace: incorrect starting fuel");
        require(gameTank[tokenId].battery == input[3], "MercuryGameFlightRace: incorrect starting battery");
        require(
            2 ** (collection.aviationLevels(tokenId) - 1) == input[7], "MercuryGameFlightRace: incorrect level scaler"
        );
        require(
            _mapHashes.verifyMapC1(collection.aviationLevels(tokenId), input[8]), "MercuryGameFlightRace: incorrect c1"
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
        uint256[101] memory usedResourcesInput,
        MercuryBase collection
    ) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 3, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "MercuryGameFlightRace: no matched opponent");
        require(gameState[matchedAviationIDs[tokenId]] >= 3, "MercuryGameFlightRace: incorrect opponent gameState");
        require(committedHash[tokenId].seed_hash == poseidon(seed, seed), "MercuryGameFlightRace: incorrect seed hash");
        require(committedHash[tokenId].time_hash == poseidon(time, seed), "MercuryGameFlightRace: incorrect time hash");
        require(committedHash[tokenId].path_hash == pathInput[0], "MercuryGameFlightRace: incorrect path hash");
        require(
            committedHash[tokenId].used_resources_hash == usedResourcesInput[0],
            "MercuryGameFlightRace: incorrect used resources hash"
        );
        require(
            _computeHashPathDataVerifier.verifyProof(pathA, pathB, pathC, pathInput),
            "MercuryGameFlightRace: incorrect path proof"
        );
        require(
            _computeHashPathDataVerifier.verifyProof(usedResourcesA, usedResourcesB, usedResourcesC, usedResourcesInput),
            "MercuryGameFlightRace: incorrect used resources hash"
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

    function postGameCleanUp(uint256 tokenId, MercuryBase collection) external {
        require(
            isApprovedForGame(tokenId, collection) || collection.ownerOf(tokenId) == address(0),
            "MercuryGameFlightRace: caller is not token owner or approved"
        );
        require(
            gameState[tokenId] == 5 || gameState[tokenId] == 6 || gameState[tokenId] == 7,
            "MercuryGameFlightRace: incorrect gameState"
        );

        reset(tokenId, gameState[tokenId] == 5 || gameState[tokenId] == 6, collection);
    }

    function claimTimeoutPenalty(uint256 tokenId, MercuryBase collection) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] > 0, "MercuryGameFlightRace: incorrect gameState");
        require(gameState[tokenId] < 5, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "MercuryGameFlightRace: no matched opponent");
        require(timeout[matchedAviationIDs[tokenId]] > 0, "MercuryGameFlightRace: timeout isn't defined");
        require(
            block.timestamp > timeout[matchedAviationIDs[tokenId]], "MercuryGameFlightRace: timeout didn't pass yet"
        );

        win(tokenId);
        lose(matchedAviationIDs[tokenId]);
    }

    function withdrawFromQueue(uint256 tokenId, MercuryBase collection) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] == 0, "MercuryGameFlightRace: already has matched opponent");

        matchingQueues[collection.aviationLevels(tokenId)] = 0;

        reset(tokenId, false, collection);
    }

    function retreat(uint256 tokenId, MercuryBase collection) external {
        require(isApprovedForGame(tokenId, collection), "MercuryGameFlightRace: caller is not token owner or approved");
        require(gameState[tokenId] == 1 || gameState[tokenId] == 2, "MercuryGameFlightRace: incorrect gameState");
        require(matchedAviationIDs[tokenId] != 0, "MercuryGameFlightRace: no matched opponent");

        escape(tokenId);
        win(matchedAviationIDs[tokenId]);
    }

    function reset(uint256 tokenId, bool clearTank, MercuryBase collection) internal {
        collection.aviationUnlock(tokenId);
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
            collection.refundResourcesFromGame(address(this), collection.ownerOf(tokenId), ids, resourceAmounts);
        }
        delete gameTank[tokenId];

        /*
        if (gameState[tokenId] == 5) {
            if (collection._aviationLevels(tokenId) == 1) {
                collection.aviationGainCounter(tokenId);
            }
            collection.aviationGainCounter(tokenId);
        } else if (gameState[tokenId] == 6 || gameState[tokenId] == 7) {
            collection.aviationLevelDown(tokenId, 1);
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
    ) external {
        LibDiamond.enforceIsContractOwner();
        _gameboardTraverseVerifier = GameboardTraverseVerifier(gameboardTraverseVerifierAddress);
        _computeHashPathDataVerifier = ComputeHashPathDataVerifier(computeHashPathDataVerifierAddress);
        _mapHashes = MapHashes(mapHashesAddress);
    }
}
