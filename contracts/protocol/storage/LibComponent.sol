// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibComponent {
    bytes32 constant SKYLABBASE_STORAGE_POSITION = keccak256("diamond.standard.componentindex.storage");

    struct ComponentIndexStorage {
        mapping(address => bool) isValidAviation;
        mapping(address => bool) isValidGame;
        mapping(address => bool) isValidPilotCollection;
        address pilotAddress;
    }

    event ValidAviation(address, bool);
    event ValidGame(address, bool);
    event ValidPilotCollection(address, bool);
    event RegisterPilot(address);

    function layout() internal pure returns (ComponentIndexStorage storage cid) {
        bytes32 position = SKYLABBASE_STORAGE_POSITION;
        assembly {
            cid.slot := position
        }
    }

    function isValidAviation(address _aviation) internal view returns (bool) {
        return layout().isValidAviation[_aviation];
    }

    function isValidGame(address _game) internal view returns (bool) {
        return layout().isValidGame[_game];
    }

    function isValidPilotCollection(address _pilot) internal view returns (bool) {
        return layout().isValidPilotCollection[_pilot];
    }

    function getPilotAddress() internal view returns (address) {
        return layout().pilotAddress;
    }
}
