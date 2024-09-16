// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Mercs.sol";
import "@solidstate/token/ERC721/enumerable/ERC721Enumerable.sol";
import "@solidstate/token/ERC721/SolidStateERC721.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Paper is ERC721Enumerable, SolidStateERC721 {
    uint256 public cap;
    uint256 public price;
    uint256 nextTokenId;
    Mercs public mercs;
    address public jarTournament;

    function initialize(string memory _name, string memory _symbol, string memory _baseTokenURI,uint256 _cap, uint256 _price, Mercs _mercs, address _jarTournament) public {
        LibDiamond.enforceIsContractOwner();
        ERC721MetadataStorage.Layout storage layout = ERC721MetadataStorage.layout();
        layout.baseURI = _baseTokenURI;
        layout.name = _name;
        layout.symbol = _symbol;
        jarTournament = _jarTournament;
        cap = _cap;
        price = _price;
        mercs = _mercs;
    }

    function mint(uint256 amount) public payable {
        require(msg.value == price * amount, "Paper: price doesn't match");
        require(_totalSupply() + amount <= cap, "Paper: exceed cap");
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, nextTokenId + 1);
            nextTokenId++;
        }
    }

    function burn(uint256 amount) public {
        require(msg.sender == jarTournament, "Paper: permission deny");
        uint256 userBalance = _balanceOf(msg.sender);
        require(userBalance >= amount, "Paper: balance insufficient");
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            _burn(tokenId);
        }
        payable(jarTournament).transfer(address(this).balance);
    }
    function exchangeMerc(uint256 amount) public {
        uint256 userBalance = _balanceOf(msg.sender);
        require(userBalance >= amount, "Paper: balance insufficient");
        for (uint i = 0; i < amount; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            _burn(tokenId);
        }
        mercs.mint(amount);
    }
}