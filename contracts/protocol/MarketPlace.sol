// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard {
    struct Bid {
        address bidder;
        uint256 price;
    }

    struct LevelInfo {
        Bid[] bids;
        uint256 lastTransactedPrice;
    }

    mapping(uint256 => LevelInfo) public levelInfos; // level to LevelInfo

    function bid(MercuryBase aviation, uint256 tokenId) public payable {
        require(aviation.isApprovedOrOwner(msg.sender, tokenId), 'MarketPlace: not owner or approver');
        uint256 level = aviation.aviationLevels(tokenId);

        Bid memory newBid = Bid({
            bidder: msg.sender,
            price: msg.value
        });

        Bid[] storage bidList = levelInfos[level].bids;
        bidList.push(newBid);
        _heapifyUp(bidList, bidList.length - 1);
    }

    function cancelBid(uint256 level) public nonReentrant {
        Bid[] storage bidList = levelInfos[level].bids;
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == msg.sender) {
                payable(msg.sender).transfer(bidList[i].price);
                _remove(bidList, i);
                break;
            }
        }
    }

    function sell(MercuryBase aviation, uint256 tokenId) public nonReentrant {
        require(aviation.isApprovedOrOwner(msg.sender, tokenId), 'MarketPlace: not owner or approver');
        uint256 level = aviation.aviationLevels(tokenId);

        Bid[] storage bidList = levelInfos[level].bids;
        require(bidList.length > 0, "No bids available");

        Bid memory highestBid = bidList[0];

        // Transfer the plane to the highest bidder
        aviation.transferFrom(msg.sender, highestBid.bidder, tokenId);

        // Transfer the highest bid amount to the seller
        payable(msg.sender).transfer(highestBid.price);

        // Update last transacted price
        levelInfos[level].lastTransactedPrice = highestBid.price;

        // Remove the highest bid
        _remove(bidList, 0);
    }

    function getHighestBid(uint256 level) public view returns (uint256) {
        Bid[] storage bidList = levelInfos[level].bids;
        if (bidList.length == 0) {
            return 0;
        } else {
            return bidList[0].price;
        }
    }

    function getLastTransactedPrice(uint256 level) public view returns (uint256) {
        return levelInfos[level].lastTransactedPrice;
    }

    // Helper functions for heap operations

    function _heapifyUp(Bid[] storage bidList, uint256 index) private {
        while (index > 0 && bidList[_parent(index)].price < bidList[index].price) {
            _swap(bidList, _parent(index), index);
            index = _parent(index);
        }
    }

    function _heapifyDown(Bid[] storage bidList, uint256 index) private {
        uint256 maxIndex = index;
        uint256 leftChild = _leftChild(index);
        uint256 rightChild = _rightChild(index);

        if (leftChild < bidList.length && bidList[leftChild].price > bidList[maxIndex].price) {
            maxIndex = leftChild;
        }

        if (rightChild < bidList.length && bidList[rightChild].price > bidList[maxIndex].price) {
            maxIndex = rightChild;
        }

        if (maxIndex != index) {
            _swap(bidList, index, maxIndex);
            _heapifyDown(bidList, maxIndex);
        }
    }

    function _remove(Bid[] storage bidList, uint256 index) private {
        require(index < bidList.length, "Index out of bounds");

        if (index == bidList.length - 1) {
            bidList.pop();
        } else {
            bidList[index] = bidList[bidList.length - 1];
            bidList.pop();
            
            if (index > 0 && bidList[index].price > bidList[_parent(index)].price) {
                _heapifyUp(bidList, index);
            } else {
                _heapifyDown(bidList, index);
            }
        }
    }

    function _parent(uint256 index) private pure returns (uint256) {
        return (index - 1) / 2;
    }

    function _leftChild(uint256 index) private pure returns (uint256) {
        return 2 * index + 1;
    }

    function _rightChild(uint256 index) private pure returns (uint256) {
        return 2 * index + 2;
    }

    function _swap(Bid[] storage bidList, uint256 i, uint256 j) private {
        Bid memory temp = bidList[i];
        bidList[i] = bidList[j];
        bidList[j] = temp;
    }
}