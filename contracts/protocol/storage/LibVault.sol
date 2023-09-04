// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "../../aviation/base/MercuryBase.sol";

library LibVault {
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("diamond.standard.vault.storage");

    struct VaultStorage {
        MercuryBase mercuryBaseNFT;
    }

    function layout() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function mercuryBaseNFT() internal view returns (MercuryBase) {
        return layout().mercuryBaseNFT;
    }
}
