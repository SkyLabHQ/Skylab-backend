// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ComponentIndex is Ownable {

    mapping(address => bool) public isValidCollection;
    mapping(address => bool) public isValidGame;
    mapping(address => bool) public isPilotCollection;

    event ValidCollection(address, bool);
    event ValidGame(address, bool);
    event PilotCollection(address, bool);

    function updateValidCollection(address _collection, bool _isValid) public onlyOwner {
        isValidCollection[_collection] = _isValid;
        emit ValidCollection(_collection, _isValid);
    }
    
    function updateValidGame(address _game, bool _isValid) public onlyOwner {
        isValidGame[_game] = _isValid;
        emit ValidGame(_game, _isValid);
    }

    function updatePilotCollection(address _pilot, bool _isValid) public onlyOwner {
        isPilotCollection[_pilot] = _isValid;
        emit PilotCollection(_pilot, _isValid);
    }
}