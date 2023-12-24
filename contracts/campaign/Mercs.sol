// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../leaderboard/PilotMileage.sol";
import "./BabyMercs.sol";
import "@solidstate/token/ERC721/SolidStateERC721.sol";

contract Mercs is SolidStateERC721 {
    address public babyMercs;
    mapping(uint256 => uint256) public babyMercsUP;
    uint256 public nextTokenId;
    address public leaderBoard;

    function claimUpgradeablePoints(uint256 tokenId) public {
        (bool isFiftyPercentage, uint256 totalMileage) = isFiftyPercentageAndTotalMileage(tokenId);
        require(isFiftyPercentage, "not fifty percentage");
        require(BabyMercs(babyMercs).ownerOf(tokenId) == msg.sender, "not owner");
        uint256 upgradePoints = PilotMileage(leaderBoard).getPilotMileage(babyMercs, tokenId) / totalMileage * 100;
        babyMercsUP[tokenId] += upgradePoints;
    }

    function mint(uint256 tokenId) public {
        require(babyMercsUP[tokenId] >= 100, "upgrade point does not meets requirement");
        require(BabyMercs(babyMercs).ownerOf(tokenId) == msg.sender, "not owner");
        babyMercsUP[tokenId] -= 100;
        BabyMercs(babyMercs).burn(tokenId);
        _safeMint(msg.sender, nextTokenId + 1);
    }

    function isFiftyPercentageAndTotalMileage(uint256 tokenId) private returns (bool, uint256) {
        uint256 total = BabyMercs(babyMercs).nextTokenId() - 1;
        uint256[] memory mileages;
        for (uint256 i = 1; i <= total; i++) {
            uint256 mileage = PilotMileage(leaderBoard).getPilotMileage(babyMercs, i);
            mileages[i - 1] = mileage;
        }
        quickSort(mileages, int256(0), int256(mileages.length - 1));
        uint256 mid = mileages[mileages.length / 2];
        uint256 totalMilead;
        for (uint256 i = 0; i <= mid; i++) {
            totalMilead += mileages[i];
        }
        return (PilotMileage(leaderBoard).getPilotMileage(babyMercs, tokenId) >= mid, totalMilead);
    }

    function quickSort(uint256[] memory _arr, int256 left, int256 right) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = _arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (_arr[uint256(i)] < pivot) i++;
            while (pivot < _arr[uint256(j)]) j--;
            if (i <= j) {
                (_arr[uint256(i)], _arr[uint256(j)]) = (_arr[uint256(j)], _arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) quickSort(_arr, left, j);
        if (i < right) quickSort(_arr, i, right);
    }
}
