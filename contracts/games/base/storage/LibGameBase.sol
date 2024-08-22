// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibGameBase {
    bytes32 constant MERCURYGAMEBASE_STORAGE_POSITION = keccak256("diamond.standard.mercurygamebase.storage");

    struct MercuryGameBaseStorage {
        address protocol;
        // token id => burner address
        mapping(uint256 => address) gameApprovals;
        mapping(address => uint256) burnerAddressToTokenId;
        mapping(address => address) burnerAddressToAviation;
    }

    function layout() internal pure returns (MercuryGameBaseStorage storage mgbs) {
        bytes32 position = MERCURYGAMEBASE_STORAGE_POSITION;
        assembly {
            mgbs.slot := position
        }
    }

    function burnerAddressToTokenId(address burner) internal view returns (uint256) {
        return layout().burnerAddressToTokenId[burner];
    }

    function burnerAddressToAviation(address burner) internal view returns (address) {
        return layout().burnerAddressToAviation[burner];
    }

    function protocol() internal view returns (address) {
        return layout().protocol;
    }

    function gameApprovals(uint256 tokenId) internal view returns (address) {
        return layout().gameApprovals[tokenId];
    }
}
