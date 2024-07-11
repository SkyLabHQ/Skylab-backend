// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibComponent} from "./storage/LibComponent.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";

contract LoyaltyPoints {

    address public admin;
    mapping(address player => uint256 point) public loyaltyPoints;
    mapping(address player => uint256 onlineStreak) public onlineStreak;
    mapping(address player => uint256 lastPlayTime) public lastPlayTime;

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

    function updatePoint(address _player, uint256 _point) public {
        require(msg.sender == admin, "Not admin");
        loyaltyPoints[_player] = _point;
    }

    function playGame(address player, uint256 tokenId) external {
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
        uint256 level = MercuryBase(msg.sender).aviationLevels(tokenId);
        uint256 point = levelToXP(level);
        loyaltyPoints[player] += point * 12 ** (onlineStreak[player] - 1) / 10 ** (onlineStreak[player] - 1);
    }

    function levelToXP(uint256 level) public pure returns(uint256) {
        //todo: need algorithm
        return level;
    }
} 