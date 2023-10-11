// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/token/ERC1155/SolidStateERC1155.sol";
import "@solidstate/token/ERC1155/metadata/IERC1155Metadata.sol";
import "@solidstate/token/ERC1155/metadata/ERC1155MetadataInternal.sol";
import "@solidstate/interfaces/IERC1155.sol";
import "@solidstate/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibComponent} from "./storage/LibComponent.sol";

// Design decision: no player interaction with this contract
contract MercuryResources is SolidStateERC1155 {
    using Strings for uint256;

    modifier onlyAviation() {
        require(LibComponent.isValidAviation(msg.sender), "MercuryResources: msg.sender is not aviation");
        _;
    }

    function initMercuryResources(string memory metadataBaseURI) public {
        LibDiamond.enforceIsContractOwner();
        ERC1155MetadataInternal._setBaseURI(metadataBaseURI);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
    }

    /*//////////////////////////////////////////////////////////////
                            Aviation Function
    //////////////////////////////////////////////////////////////*/

    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlyAviation {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        external
        onlyAviation
    {
        _mintBatch(to, ids, amounts, data);
    }

    function playTestNuke(address player, uint256[] memory ids) external onlyAviation {
        for (uint256 i = 0; i < ids.length; i++) {
            ERC1155BaseInternal._burn(player, ids[i], balanceOf(player, ids[i]));
        }
    }

    function burn(address from, uint256[] memory ids, uint256[] memory amounts) external onlyAviation {
        ERC1155BaseInternal._burnBatch(from, ids, amounts);
    }

    /*//////////////////////////////////////////////////////////////
                            View Function
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual override(ERC1155Metadata, IERC1155Metadata) returns (string memory) {
        return string(abi.encodePacked(ERC1155Metadata.uri(id), ".json"));
    }

    /*//////////////////////////////////////////////////////////////
                            Admin Function
    //////////////////////////////////////////////////////////////*/

    function registerMetadataURI(string memory metadataURI) external {
        LibDiamond.enforceIsContractOwner();
        ERC1155MetadataInternal._setBaseURI(metadataURI);
    }
}
