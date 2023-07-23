// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Design decision: no player interaction with this contract
contract SkylabResources is ERC1155, Ownable {
    using Strings for uint;
    
    address private  _sky;
    string private _metadataBaseURI;

    modifier onlySky() {
        require(msg.sender == _sky, "SkylabResources: msg.sender is not Sky");
        _;
    }

    constructor(address skylabBaseAddress, string memory metadataBaseURI) ERC1155("") {
        _sky = skylabBaseAddress;
        _metadataBaseURI = metadataBaseURI;
    }

    function setSky(address sky) external onlyOwner {
        _sky = sky;
    }

    // Can only be minted by SkylabBase contract
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external onlySky {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external onlySky {
        _mintBatch(to, ids, amounts, data);
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) override public virtual {
        
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) override public virtual {
        
    }

    function playTestNuke(address player, uint256[] memory ids) external onlySky {
        for (uint256 i = 0; i < ids.length; i++) {
            ERC1155._burn(player, ids[i], balanceOf(player, ids[i]));
        }
    }
 
    function burn(address from, uint256[] memory ids, uint256[] memory amounts) external onlySky {
        ERC1155._burnBatch(from, ids, amounts);
    }

    function uri(uint256 id) override public view virtual returns (string memory) {
        return string(
                    abi.encodePacked(
                        _metadataBaseURI,
                        id.toString(),
                        ".json"
                    )  
                );
    }

    function registerMetadataURI(string memory metadataURI) external onlyOwner {
        _metadataBaseURI = metadataURI;
    }
}
