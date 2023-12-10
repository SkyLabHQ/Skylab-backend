// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PrivateLobby} from "./PrivateLobby.sol";

contract PrivateLobbyFactory {
    mapping(address => string) public privateLobbyName;
    mapping(string => address) public nameToPravateLobby;
    mapping(string => bool) public isNameExist;
    string private constant characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    string[] public names;

    function createPrivateLobby(address _mercuryBidTacToe) public returns (address) {
        string memory name = generateRandomCharacters();
        while(isNameExist[name]) {
            name = generateRandomCharacters();
        }
        isNameExist[name] = true;
        PrivateLobby privateLobby = new PrivateLobby(_mercuryBidTacToe, name);
        privateLobbyName[address(privateLobby)] = name;
        nameToPravateLobby[name] = address(privateLobby);
        names.push(name);
        return address(privateLobby);
    }

    function clean(string memory name) public {
        require(msg.sender == nameToPravateLobby[name], "PrivateLobbyFactory: not admin");
        delete nameToPravateLobby[name];
        delete privateLobbyName[msg.sender];
        delete isNameExist[name];
        for (uint i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
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


