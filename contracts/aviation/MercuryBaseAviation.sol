// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MercuryBase} from "./base/MercuryBase.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibBase} from "./base/storage/LibBase.sol";

contract MercuryBaseAviation is MercuryBase {
    bool public mintable;
    uint256 public price;

    function initialize(
        bool _mintable,
        uint256 _price,
        string memory _baseURI,
        string memory _name,
        string memory _symbol,
        address _protocol
    ) public {
        super.initialize(_baseURI, _name, _symbol, _protocol);
        mintable = _mintable;
        price = _price;
    }

    modifier onlyMintable() {
        require(mintable, "MercuryBase: Mint not open");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                            Mint Function
    //////////////////////////////////////////////////////////////*/

    function mintAviation(address to) external payable virtual onlyMintable {
        require(msg.value == price, "MercuryBase: Incorrect price");
        baseMint(to);
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/

    function setMintable(bool _mintable) external {
        LibDiamond.enforceIsContractOwner();
        mintable = _mintable;
    }

    function setPrice(uint256 _price) external {
        LibDiamond.enforceIsContractOwner();
        price = _price;
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        uint256 point = LibBase.layout().aviationPoints[tokenId];
        uint256 level = LibBase.layout().aviationLevels[tokenId];
        uint256 taxRate;
        if (level <= 9 && level >= 1) {
            taxRate = 4 + 2 * (level - 1);
        } else {
            taxRate = 20;
        }
        payable(address(this)).transfer(taxRate * point * 1e16);
        super._transfer(from, to, tokenId);
    }
}
