// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Base64 } from "./Base64.sol";

contract SkylabMetadata {
    function generateTokenMetadataa(string memory tokenId, string memory imageUrl, string memory tokenLevelString, string memory pilotString) external pure returns (string memory) {
        
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#', tokenId, '",',
                        '"image": "', imageUrl, '",',
                        '"attributes": [',
                            '{',
                                '"trait_type": "Level",',
                                '"value": ', tokenLevelString, 
                            '},',
                            '{',
                                '"trait_type": "Pilot",',
                                '"value": "', pilotString, '"',
                            '}',
                        ']'
                    '}'
                    )
                )
            )
        );
        
        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}