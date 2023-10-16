// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "../libraries/Base64.sol";

contract BabyMercs is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string internal _imageBaseURI;

    constructor(string memory baseURI, string memory name, string memory symbol) ERC721(name, symbol) Ownable() {
        _imageBaseURI = baseURI;
    }

    function publicMint(address to) public payable {
        require(msg.value >= 0.001 ether, "BabyMercs: 0.001 eth required");
        _safeMint(to, totalSupply() + 1);
    }

    function airdrop(address to) public onlyOwner {
        _safeMint(to, totalSupply() + 1);
    }

    function registerImageBaseURI(string memory baseURI) external onlyOwner {
        _imageBaseURI = baseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "#',
                        tokenId.toString(),
                        '",',
                        '"image": "',
                        string(abi.encodePacked(_imageBaseURI, tokenId.toString(), ".png")),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
