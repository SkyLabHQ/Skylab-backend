// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";

contract MarketPlace {

    struct Bid {
        address bidder;
        uint256 price;
        uint256 timestamp;
    }

    struct LevelInfo {
        Bid[] bids;
        uint256 lastTransactedPrice;
    }

    mapping(uint256 => LevelInfo) public levelInfos; // level to LevelInfo
    mapping(address => mapping(uint256 => uint256)) public userBids; // user address => level => bid index (from 1 -> length)

    function bid(MercuryBase aviation, uint256 tokenId) public payable {
        uint256 level = aviation.aviationLevels(tokenId);
        require(msg.value > 0, "Bid amount must be greater than 0");
        require(userBids[msg.sender][level] == 0, "You already have a bid for this level");

        LevelInfo storage levelInfo = levelInfos[level];
        Bid memory newBid = Bid(msg.sender, msg.value, block.timestamp);

        levelInfo.bids.push(newBid);
        userBids[msg.sender][level] = levelInfo.bids.length;
    }

    function cancelBid(uint256 level) public {
        uint256 bidIndex = userBids[msg.sender][level];
        require(bidIndex > 0, "No bid found for this level");

        LevelInfo storage levelInfo = levelInfos[level];
        uint256 actualIndex = bidIndex - 1; // Convert to 0-based index
        uint256 lastIndex = levelInfo.bids.length - 1;
        uint256 bidAmount = levelInfo.bids[actualIndex].price;

        if (actualIndex != lastIndex) {
            // Move the last bid to the canceled bid's position
            levelInfo.bids[actualIndex] = levelInfo.bids[lastIndex];
            
            // Update the moved bid's index in userBids
            address movedBidder = levelInfo.bids[lastIndex].bidder;
            userBids[movedBidder][level] = bidIndex; // Keep it 1-based for userBids
        }
        levelInfo.bids.pop();

        // Reset user's bid index
        userBids[msg.sender][level] = 0;

        // Return the bid amount to the user
        payable(msg.sender).transfer(bidAmount);
    }

    function sell(MercuryBase aviation, uint256 tokenId) public {
        uint256 level = aviation.aviationLevels(tokenId);
        LevelInfo storage levelInfo = levelInfos[level];
        require(levelInfo.bids.length > 0, "No bids for this level");

        require(aviation.isApprovedOrOwner(msg.sender, tokenId), "You don't own this token");
        require(aviation.getApproved(tokenId) == address(this), "Contract not approved for this token");

        (uint256 highestBidIndex, Bid memory highestBid) = findHighestBid(level);
        address buyer = highestBid.bidder;
        uint256 price = highestBid.price;
        address owner = aviation.ownerOf(tokenId);
        // Transfer the token
        aviation.transferFrom(owner, buyer, tokenId);

        // Remove the highest bid
        uint256 lastIndex = levelInfo.bids.length - 1;
        if (highestBidIndex != lastIndex) {
            // Move the last bid to the highest bid's position
            levelInfo.bids[highestBidIndex] = levelInfo.bids[lastIndex];
            // Update the moved bid's index in userBids
            address movedBidder = levelInfo.bids[highestBidIndex].bidder;
            userBids[movedBidder][level] = highestBidIndex + 1; // +1 because userBids uses 1-based index
        }
        levelInfo.bids.pop();

        // Reset buyer's bid index in userBids
        userBids[buyer][level] = 0;

        // Update last transacted price
        levelInfo.lastTransactedPrice = price;

        // Transfer the funds to the seller
        payable(msg.sender).transfer(price);
    }

    function findHighestBid(uint256 level) internal view returns (uint256, Bid memory) {
        LevelInfo storage levelInfo = levelInfos[level];
        require(levelInfo.bids.length > 0, "No bids for this level");

        uint256 highestBidIndex = 0;
        Bid memory highestBid = levelInfo.bids[0];

        for (uint256 i = 1; i < levelInfo.bids.length; i++) {
            if (levelInfo.bids[i].price > highestBid.price || 
               (levelInfo.bids[i].price == highestBid.price && 
                levelInfo.bids[i].timestamp < highestBid.timestamp)) {
                highestBid = levelInfo.bids[i];
                highestBidIndex = i;
            }
        }

        return (highestBidIndex, highestBid);
    }

    function getHighestBid(uint256 level) public view returns (uint256) {
        (,Bid memory highestBid) = findHighestBid(level);
        return highestBid.price;
    }

    function getLastTransactedPrice(uint256 level) public view returns (uint256) {
        return levelInfos[level].lastTransactedPrice;
    }
}