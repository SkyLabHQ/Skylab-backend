// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ComponentIndex} from "../../../protocol/ComponentIndex.sol";
import {MercuryResources} from "../../../protocol/MercuryResources.sol";
import {MercuryPilots} from "../../../protocol/MercuryPilots.sol";

library LibBase {
    using Strings for uint256;

    uint256 constant MAXLEVEL = 16;
    bytes32 constant MERCURYBASE_STORAGE_POSITION = keccak256("diamond.standard.mercurybase.storage");

    struct MercuryBaseStorage {
        address protocol;
        string metadataBaseURI;
        uint256 lastTokenID;
        mapping(uint256 => uint256) aviationLevels;
        mapping(uint256 => uint256) aviationPoints;
        mapping(uint256 => bool) aviationTradeLock;
    }

    event MovePoints(uint256 fromTokenID, uint256 toTokenID, uint256 points);
    event UpdateLevels(uint256 tokenID, uint256 level);

    function layout() internal pure returns (MercuryBaseStorage storage sbs) {
        bytes32 position = MERCURYBASE_STORAGE_POSITION;
        assembly {
            sbs.slot := position
        }
    }

    function mercuryResources() internal view returns (MercuryResources) {
        return MercuryResources(layout().protocol);
    }

    function componentIndex() internal view returns (ComponentIndex) {
        return ComponentIndex(layout().protocol);
    }

    function pilot() internal view returns (MercuryPilots) {
        return MercuryPilots(layout().protocol);
    }

    function generateTokenMetadata(uint256 tokenId, string memory imageUrlSuffix)
        internal
        view
        returns (string memory)
    {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',
                        tokenId.toString(),
                        '",',
                        '"image": "',
                        string(abi.encodePacked(layout().metadataBaseURI, imageUrlSuffix)),
                        '",',
                        '"attributes": [',
                        "{",
                        '"trait_type": "Level",',
                        '"value": ',
                        layout().aviationLevels[tokenId].toString(),
                        "},",
                        "{",
                        '"trait_type": "Point",',
                        '"value": ',
                        layout().aviationPoints[tokenId].toString(),
                        "}",
                        "]" "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
