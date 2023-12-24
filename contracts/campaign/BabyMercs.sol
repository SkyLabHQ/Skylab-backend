// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/token/ERC721/SolidStateERC721.sol";
import "@solidstate/token/ERC721/metadata/ERC721MetadataStorage.sol";
import "@solidstate/token/ERC721/metadata/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "../libraries/Base64.sol";
import "@solidstate/interfaces/IERC721.sol";
import "@solidstate/interfaces/IERC165.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract BabyMercs is SolidStateERC721 {
    using Strings for uint256;

    uint256 public nextTokenId;

    //helper function
    function updateNextTokenId() public {
        LibDiamond.enforceIsContractOwner();
        nextTokenId = totalSupply();
    }

    function initialize(string memory _name, string memory _symbol, string memory _baseTokenURI) public {
        LibDiamond.enforceIsContractOwner();
        ERC721MetadataStorage.Layout storage layout = ERC721MetadataStorage.layout();
        layout.baseURI = _baseTokenURI;
        layout.name = _name;
        layout.symbol = _symbol;
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
    }

    function publicMint(address to, uint256 amount) public payable {
        require(msg.value == 0.001 ether * amount, "BabyMercs: 0.001 * amount eth required");
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(to, nextTokenId + 1);
            nextTokenId++;
        }
    }

    function airdrop(address to) public {
        LibDiamond.enforceIsContractOwner();
        _safeMint(to, nextTokenId + 1);
        nextTokenId++;
    }

    function registerImageBaseURI(string memory baseURI) external {
        LibDiamond.enforceIsContractOwner();
        ERC721MetadataStorage.Layout storage layout = ERC721MetadataStorage.layout();
        layout.baseURI = baseURI;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "BabyMercs: burn caller is not owner nor approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Metadata, IERC721Metadata)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        string memory _imageBaseURI = ERC721MetadataStorage.layout().baseURI;
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
