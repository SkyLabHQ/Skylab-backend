// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibComponent} from "./storage/LibComponent.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";

contract LoyaltyPoints {

    address public admin;
    mapping(address => uint256) public loyaltyPoints;
    mapping(address => uint256) public onlineStreak;
    mapping(address => uint256) public lastPlayTime;
    mapping(address => bool) public userExists;
    address[] public userList;

    function initLoyaltyPoints(address _admin) public {
        LibDiamond.enforceIsContractOwner();
        admin = _admin;
    }

    function transferAdmin(address _admin) public {
        LibDiamond.enforceIsContractOwner();
        admin = _admin;
    }

    function getCurrentDay() internal view returns (uint256) {
        return block.timestamp / 1 days;
    }

    function addPoint(address _player, uint256 _point) public {
        require(msg.sender == admin, "Not admin");
        addUserIfNotExists(_player);
        loyaltyPoints[_player] += _point;
    }

    function playGame(address player, uint256 pointsTransferred) external {
        require(LibComponent.isValidAviation(msg.sender), "LoyaltyPoints: msg.sender is not a valid aviation. ");
        uint256 today = getCurrentDay();
        if (lastPlayTime[player] != today) {
            if (lastPlayTime[player] == today - 1) {
                onlineStreak[player]++;
            } else {
                onlineStreak[player] = 1;
            }
            lastPlayTime[player] = today;
        }
        loyaltyPoints[player] += pointsTransferred * 100 * 12 ** (onlineStreak[player] - 1) / 10 ** (onlineStreak[player] - 1);
        addUserIfNotExists(player);
    }

    function addUserIfNotExists(address player) private {
        if(!userExists[player]) {
            userList.push(player);
            userExists[player] = true;
        }
    }
    function pointList() public view returns (uint256[] memory) {
        uint256[] memory points = new uint256[](userList.length);
        for (uint i = 0; i < userList.length; i++) {
            points[i] = loyaltyPoints[userList[i]];
        }
        return points;
    }
} 