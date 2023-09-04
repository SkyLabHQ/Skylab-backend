// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibComponent} from "./storage/LibComponent.sol";

contract ComponentIndex {
    function setValidAviation(address _collection, bool _isValid) public {
        LibDiamond.enforceIsContractOwner();
        LibComponent.layout().isValidAviation[_collection] = _isValid;
        emit LibComponent.ValidAviation(_collection, _isValid);
    }

    function setValidGame(address _game, bool _isValid) public {
        LibDiamond.enforceIsContractOwner();
        LibComponent.layout().isValidGame[_game] = _isValid;
        emit LibComponent.ValidGame(_game, _isValid);
    }

    function setValidPilot(address _pilot, bool _isValid) public {
        LibDiamond.enforceIsContractOwner();
        LibComponent.layout().isValidPilot[_pilot] = _isValid;
        emit LibComponent.ValidPilot(_pilot, _isValid);
    }

    function isValidAviation(address _collection) external view returns (bool) {
        return LibComponent.isValidAviation(_collection);
    }

    function isValidGame(address _game) external view returns (bool) {
        return LibComponent.isValidGame(_game);
    }

    function isValidPilot(address _pilot) external view returns (bool) {
        return LibComponent.isValidPilot(_pilot);
    }
}
