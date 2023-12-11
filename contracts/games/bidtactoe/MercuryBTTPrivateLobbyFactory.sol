// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBTTPrivateLobby} from "./MercuryBTTPrivateLobby.sol";

contract MercuryBTTPrivateLobbyFactory {
    mapping(address => string) public privateLobbyName;
    mapping(string => address) public nameToPravateLobby;
    mapping(address => bool) public hasJoined;
    string private constant characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    function createPrivateLobby(address _mercuryBidTacToe) public returns (address) {
        string memory name = generateRandomCharacters();
        while(nameToPravateLobby[name] != address(0)) {
            name = generateRandomCharacters();
        }
        MercuryBTTPrivateLobby privateLobby = new MercuryBTTPrivateLobby(_mercuryBidTacToe, name);
        privateLobbyName[address(privateLobby)] = name;
        nameToPravateLobby[name] = address(privateLobby);
        return address(privateLobby);
    }

    function setHasJoined(string memory name, bool joined) public {
        require(msg.sender == nameToPravateLobby[name], "PrivateLobbyFactory: not admin");
        hasJoined[msg.sender] = joined;
    }

    function clean(string memory name) public {
        require(msg.sender == nameToPravateLobby[name], "PrivateLobbyFactory: not admin");
        delete nameToPravateLobby[name];
        delete privateLobbyName[msg.sender];
    }

    function generateRandomCharacters() public view returns (string memory) {
        bytes memory charactersBytes = bytes(characters);
        bytes memory result = new bytes(4);
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, gasleft())));

        for (uint256 i = 0; i < 4; i++) {
            result[i] = charactersBytes[random % charactersBytes.length];
            random /= charactersBytes.length;
        }

        return string(result);
    }
}


