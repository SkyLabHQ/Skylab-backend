// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibComponent} from "./storage/LibComponent.sol";

contract ComponentIndex {
    /*//////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/

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

    function setValidPilotCollection(address _collection, bool _isValid) public {
        LibDiamond.enforceIsContractOwner();
        LibComponent.layout().isValidPilotCollection[_collection] = _isValid;
        emit LibComponent.ValidPilotCollection(_collection, _isValid);
    }

    function setPilotAddress(address _pilot) public {
        LibDiamond.enforceIsContractOwner();
        LibComponent.layout().pilotAddress = _pilot;
        emit LibComponent.RegisterPilot(_pilot);
    }

    /*//////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/

    function isValidAviation(address _collection) public view returns (bool) {
        return LibComponent.isValidAviation(_collection);
    }

    function isValidGame(address _game) public view returns (bool) {
        return LibComponent.isValidGame(_game);
    }

    function isValidPilotCollection(address _pilot) public view returns (bool) {
        return LibComponent.isValidPilotCollection(_pilot);
    }

    function getPilotAddress() public view returns (address) {
        return LibComponent.getPilotAddress();
    }
}
