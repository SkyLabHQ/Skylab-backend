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
    address public leagueTournament;

    function initialize(string memory _name, string memory _symbol, string memory _baseTokenURI,uint256 _cap, uint256 _price, Mercs _mercs, address _leagueTournament) public {
        LibDiamond.enforceIsContractOwner();
        ERC721MetadataStorage.Layout storage layout = ERC721MetadataStorage.layout();
        layout.baseURI = _baseTokenURI;
        layout.name = _name;
        layout.symbol = _symbol;
        leagueTournament = _leagueTournament;
        cap = _cap;
        price = _price;
        mercs = _mercs;
    }

    function mint(uint256 amount) public {
        require(_totalSupply() + amount <= cap, "Paper: exceed cap");
        for (uint i = 0; i < amount; i++) {
            _safeMint(msg.sender, nextTokenId + 1);
            nextTokenId++;
        }
    }

    function burn(uint256 tokenId) public {
        require(msg.sender == leagueTournament, "Paper: permission deny");
        _burn(tokenId);
    }
}