// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/token/ERC721/SolidStateERC721.sol";
import "@solidstate/token/ERC721/metadata/ERC721MetadataStorage.sol";
import "@solidstate/token/ERC721/metadata/IERC721Metadata.sol";
import "@solidstate/interfaces/IERC721.sol";
import "@solidstate/interfaces/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {LibBase} from "./storage/LibBase.sol";

abstract contract MercuryBase is SolidStateERC721 {
    using Strings for uint256;

    constructor(string memory baseURI, string memory name, string memory symbol) {
        ERC721MetadataStorage.Layout storage layout = ERC721MetadataStorage.layout();
        layout.name = name;
        layout.symbol = symbol;
        layout.baseURI = baseURI;
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
    }

    modifier onlyGameAddresses() {
        require(LibBase.componentIndex().isValidGame(msg.sender), "MercuryBase: msg.sender is not a valid game address");
        _;
    }

    // ====================
    // Aviation level
    // ====================
    function aviationMovePoints(uint256 winnerTokenId, uint256 loserTokenId) external onlyGameAddresses {
        require(_exists(winnerTokenId), "MercuryBase: nonexistent token");
        require(_exists(loserTokenId), "MercuryBase: nonexistent token");
        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        uint256 pointsToMove = sbs.aviationPoints[winnerTokenId]
            >= (uint256(sbs.aviationPoints[loserTokenId] + 1) / uint256(2))
            ? (uint256(sbs.aviationPoints[loserTokenId] + 1) / uint256(2))
            : sbs.aviationPoints[winnerTokenId];
        sbs.aviationPoints[winnerTokenId] += pointsToMove;
        if (pointsToMove >= sbs.aviationPoints[loserTokenId]) {
            sbs.aviationPoints[loserTokenId] = 0;
        } else {
            sbs.aviationPoints[loserTokenId] -= pointsToMove;
        }

        updateLevel(winnerTokenId);
        updateLevel(loserTokenId);

        if (sbs.aviationPoints[loserTokenId] == 0) {
            burnAviation(loserTokenId);
        }
    }

    function updateLevel(uint256 tokenId) private {
        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        for (uint256 i = 0; i <= MAXLEVEL; i++) {
            if (2 ** i > sbs.aviationPoints[tokenId]) {
                sbs.aviationLevels[tokenId] = i;
                emit LibBase.UpdateLevels(tokenId);
                return;
            }
        }
        sbs.aviationLevels[tokenId] = MAXLEVEL;
        emit LibBase.UpdateLevels(tokenId);
    }

    function burnAviation(uint256 tokenId) private {
        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        _burn(tokenId);
    }

    // ====================
    // MISC
    // ====================
    function requestResourcesForGame(address from, address game, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyGameAddresses
    {
        LibBase.mercuryResources().burn(from, ids, amounts);
        LibBase.mercuryResources().mintBatch(game, ids, amounts, "");
    }

    function refundResourcesFromGame(address game, address to, uint256[] memory ids, uint256[] memory amounts)
        external
        onlyGameAddresses
    {
        LibBase.mercuryResources().burn(game, ids, amounts);
        LibBase.mercuryResources().mintBatch(to, ids, amounts, "");
    }

    function aviationLock(uint256 tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "MercuryBase: nonexistent token");
        require(!LibBase.layout().aviationTradeLock[tokenId], "MercuryBase: aviation locked");
        LibBase.layout().aviationTradeLock[tokenId] = true;
    }

    function aviationUnlock(uint256 tokenId) external virtual onlyGameAddresses {
        require(_exists(tokenId), "MercuryBase: nonexistent token");
        require(LibBase.layout().aviationTradeLock[tokenId], "MercuryBase: aviation not locked");
        LibBase.layout().aviationTradeLock[tokenId] = false;
    }

    function isAviationLocked(uint256 tokenId) external view virtual onlyGameAddresses returns (bool) {
        require(_exists(tokenId), "MercuryBase: nonexistent token");
        return LibBase.layout().aviationTradeLock[tokenId];
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        require(!LibBase.layout().aviationTradeLock[tokenId], "MercuryBase: token is locked");
        super._transfer(from, to, tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    function registerMetadataURI(string memory metadataURI) external {
        LibDiamond.enforceIsContractOwner();
        LibBase.layout().metadataBaseURI = metadataURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Metadata, IERC721Metadata)
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        LibBase.MercuryBaseStorage storage sbs = LibBase.layout();
        return LibBase.generateTokenMetadata(
            tokenId, string(abi.encodePacked(sbs.aviationLevels[tokenId].toString(), ".svg"))
        );
    }

    //=============================VIEW FUNCTION============================

    function aviationLevels(uint256 _tokenId) public view returns (uint256) {
        return LibBase.layout().aviationLevels[_tokenId];
    }

    function aviationPoints(uint256 _tokenId) public view returns (uint256) {
        return LibBase.layout().aviationPoints[_tokenId];
    }
}
