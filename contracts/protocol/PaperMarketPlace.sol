// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import {MercuryBase} from "../aviation/base/MercuryBase.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ComponentIndex} from "./ComponentIndex.sol";

contract PaperMarketPlace {
    struct Bid {
        address bidder;
        uint256 price;
        uint256 amount;
    }

    address public valut = address(this);
    address public paper;
    Bid[] public paperBids;
    mapping(address => uint256) public paperIndex;

    function initMarketPlace(address _paper) public {
        LibDiamond.enforceIsContractOwner();
        paper = _paper;
    }

    function bidPaper(uint256 amount) public payable {
        require(msg.value > 0, "Bid amount must be greater than 0");
        require(paperIndex[msg.sender] == 0, "Already bid");
        Bid memory newBid = Bid(msg.sender, msg.value, amount);
        paperIndex[msg.sender] = paperBids.length;
        paperBids.push(newBid);
    }

    function cancelBidPaper() public {
        require(paperIndex[msg.sender] != 0, "no bid");
        uint256 actualIndex = paperIndex[msg.sender];
        uint256 lastIndex = paperBids.length - 1;
        uint256 bidPrice = paperBids[actualIndex].price;
        if (actualIndex != lastIndex) {
            paperBids[actualIndex] = paperBids[lastIndex];
            address movedBidder = paperBids[lastIndex].bidder;
            paperIndex[movedBidder] = actualIndex;
        }
        paperBids.pop();
        paperIndex[msg.sender] = 0;
        // Return the bid amount to the user
        payable(valut).transfer(bidPrice * getTaxRate() / 100);
        payable(msg.sender).transfer(bidPrice * (100 - getTaxRate()) / 100);
    }

    function reBidPaper(uint256 amount) public payable {
        cancelBidPaper();
        bidPaper(amount);
    }

    function sellPaper(address buyer) public {
        uint256 actualIndex = paperIndex[buyer];
        uint256 lastIndex = paperBids.length - 1;
        uint256 bidPrice = paperBids[actualIndex].price;
        uint256 amount = paperBids[actualIndex].amount;
        if (actualIndex != lastIndex) {
            paperBids[actualIndex] = paperBids[lastIndex];
            address movedBidder = paperBids[lastIndex].bidder;
            paperIndex[movedBidder] = actualIndex;
        }
        paperBids.pop();
        paperIndex[buyer] = 0;
        IERC20(paper).transfer(buyer, amount);
        payable(valut).transfer(bidPrice * getTaxRate() / 100);
        payable(msg.sender).transfer(bidPrice * (100 - getTaxRate()) / 100);
    }

    function getTaxRate() public pure returns(uint256) {
        return 2;
    }
}
