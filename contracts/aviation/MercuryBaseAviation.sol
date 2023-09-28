// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryBaseAviation is MercuryBase {
    bool public mintable;
    uint256 public price;

    constructor(bool _mintable, uint256 _price, string memory baseURI, string memory name, string memory symbol)
        MercuryBase(baseURI, name, symbol)
    {
        mintable = _mintable;
        price = _price;
    }

    modifier onlyMintable() {
        require(mintable, "MercuryBase: Mint not open");
        _;
    }

    // ====================
    // Mint
    // ====================
    function mintAviation(address to) external payable virtual onlyMintable {
        require(msg.value == price, "MercuryBase: Incorrect price");
        uint256 tokenID = super.totalSupply() + 1;
        _safeMint(to, tokenID);
        LibBase.layout().aviationLevels[tokenID] = 1;
    }

    // =======================
    // Admin Utility
    // =======================
    function setMintable(bool _mintable) external {
        LibDiamond.enforceIsContractOwner();
        mintable = _mintable;
    }

    function setPrice(uint256 _price) external {
        LibDiamond.enforceIsContractOwner();
        price = _price;
    }
}
