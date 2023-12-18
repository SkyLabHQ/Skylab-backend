// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBTTPrivateLobby} from "./MercuryBTTPrivateLobby.sol";

contract MercuryBTTPrivateLobbyFactory {
    mapping(address => bool) public lobbyExists;
    mapping(string => address) public nameToPrivateLobby;
    mapping(address => address) public activeLobbyPerPlayer;
    string private constant characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

    event PrivateLobbyCreated(address privateLobbyAddress, string name, address admin);

    function createPrivateLobby() external {
        string memory name = generateRandomCharacters();
        while (nameToPrivateLobby[name] != address(0)) {
            name = generateRandomCharacters();
        }
        bytes memory bytecode =
            abi.encodePacked(type(MercuryBTTPrivateLobby).creationCode, abi.encode(name, msg.sender));
        bytes32 salt = keccak256(abi.encodePacked(name, msg.sender, block.timestamp));
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        address privateLobbyAddress = address(uint160(uint256(hash)));
        nameToPrivateLobby[name] = privateLobbyAddress;
        lobbyExists[privateLobbyAddress] = true;
        new MercuryBTTPrivateLobby{salt: salt}(name, msg.sender);
        emit PrivateLobbyCreated(privateLobbyAddress, name, msg.sender);
    }

    // Most likely private lobbies are never cleaned up, so code with that assumption
    function deletePrivateLobby(string memory name) external {
        require(lobbyExists[msg.sender], "MercuryBTTPrivateLobbyFactory: caller not lobby");
        require(nameToPrivateLobby[name] == msg.sender, "MercuryBTTPrivateLobbyFactory: caller not lobby");
        delete lobbyExists[msg.sender];
        delete nameToPrivateLobby[name];
    }

    // Player management called from lobby
    function setActiveLobby(address player) public {
        require(lobbyExists[msg.sender], "MercuryBTTPrivateLobbyFactory: caller not lobby");
        activeLobbyPerPlayer[player] = msg.sender;
    }

    // Called from lobby; player may or may not deactive
    function deactiveLobbyForPlayer(address player) public {
        require(msg.sender == activeLobbyPerPlayer[player], "MercuryBTTPrivateLobbyFactory: caller not lobby");
        delete activeLobbyPerPlayer[player];
    }

    function generateRandomCharacters() private view returns (string memory) {
        bytes memory charactersBytes = bytes(characters);
        bytes memory result = new bytes(6);
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, gasleft())));

        for (uint256 i = 0; i < 6; i++) {
            result[i] = charactersBytes[random % charactersBytes.length];
            random /= charactersBytes.length;
        }

        return string(result);
    }
}
