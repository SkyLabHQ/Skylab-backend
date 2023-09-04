// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../libraries/Base64.sol";
import {MercuryResources} from "../../../protocol/MercuryResources.sol";
import {ComponentIndex} from "../../../protocol/ComponentIndex.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibBase {
    using Strings for uint256;

    bytes32 constant MERCURYBASE_STORAGE_POSITION = keccak256("diamond.standard.mercurybase.storage");

    struct MercuryBaseStorage {
        bool mintable;
        string metadataBaseURI;
        address protocol;
        mapping(uint256 => uint256) aviationLevels;
        mapping(uint256 => uint256) aviationPoints;
        mapping(uint256 => bool) aviationTradeLock;
        mapping(uint256 => uint256) aviationPilotIds;
        mapping(uint256 => address) aviationPilotAddresses;
        mapping(address => mapping(uint256 => uint256)) pilotToToken;
        mapping(address => string) pilotAddressesToNames;
        mapping(address => string) pilotAddressesToUrls;
    }

    event UpdateLevels(uint256 tokenID);

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

    function generateTokenMetadata(uint256 tokenId, string memory imageUrl, string memory pilotString)
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
                        imageUrl,
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
                        "},",
                        "{",
                        '"trait_type": "Pilot",',
                        '"value": "',
                        pilotString,
                        '"',
                        "}",
                        "]" "}"
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
