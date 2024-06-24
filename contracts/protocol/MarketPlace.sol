// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";

contract MarketPlace {

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
        uint256 i = 0;
        while (i < bidList.length && bidList[i].price > newBid.price) {
            i++;
        }
        
        bidList.push(newBid); // Add a dummy element to increase the length of the array
        
        for (uint256 j = bidList.length - 1; j > i; j--) {
            bidList[j] = bidList[j - 1];
        }
        
        bidList[i] = newBid;
    }

    function cancelBid(uint256 level) public {
        Bid[] storage bidList = levelInfos[level].bids;
        for (uint256 i = 0; i < bidList.length; i++) {
            if (bidList[i].bidder == msg.sender) {
                payable(msg.sender).transfer(bidList[i].price);
                for (uint256 j = i; j < bidList.length - 1; j++) {
                    bidList[j] = bidList[j + 1];
                }
                bidList.pop();
                break;
            }
        }
    }

    function sell(MercuryBase aviation, uint256 tokenId) public {
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
        for (uint256 i = 0; i < bidList.length - 1; i++) {
            bidList[i] = bidList[i + 1];
        }
        bidList.pop();
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
}