// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {LibDiamond} from "../../libraries/LibDiamond.sol";
import {MercuryBase} from "../../aviation/base/MercuryBase.sol";
import {LibGameBase} from "./storage/LibGameBase.sol";
import {ComponentIndex} from "../../protocol/ComponentIndex.sol";
import {IERC721} from "../../interfaces/IERC721.sol";

abstract contract MercuryGameBase is ERC1155Holder {
    using Strings for uint256;

    function initialize(address _protocol) public virtual {
        LibDiamond.enforceIsContractOwner();
        LibGameBase.layout().protocol = _protocol;
    }

    modifier onlyOwner() {
        require(LibDiamond.contractOwner() == msg.sender, "MercuryGameBase: caller is not the owner");
        _;
    }

    function baseCreateLobby(address newGame, address aviation) internal {
        LibGameBase.baseCreateLobby(newGame, aviation);
    }

    function baseJoinLobby(address lobby, address aviation) internal {
        LibGameBase.baseJoinLobby(lobby, aviation);
    }

    function baseQuitLobby(address lobby, address aviation) internal {
        LibGameBase.baseQuitLobby(lobby, aviation);
    }

    function getLobbyOnGoingGames(address aviation) external view returns (address[] memory) {
        return LibGameBase.lobbyOnGoingGames(aviation);
    }

    /*//////////////////////////////////////////////////////////////
                            Approval Function
    //////////////////////////////////////////////////////////////*/
    function isApprovedForGame(uint256 tokenId, MercuryBase aviation) public view virtual returns (bool) {
        return aviation.isApprovedOrOwner(msg.sender, tokenId) || LibGameBase.gameApprovals(tokenId) == msg.sender;
    }

    function approveForGame(address payable burner, uint256 tokenId, MercuryBase aviation) public virtual payable {
        require(componentIndex().isValidAviation(address(aviation)), "MercuryGameBase: aviation is not valid");
        require(isApprovedForGame(tokenId, aviation), "MercuryGameBase: caller is not token owner or approved");
        burner.transfer(msg.value);
        aviation.aviationLock(tokenId);
        LibGameBase.layout().gameApprovals[tokenId] = burner;
        LibGameBase.layout().burnerAddressToTokenId[burner] = tokenId;
        LibGameBase.layout().burnerAddressToAviation[burner] = address(aviation);
    }

    function unapproveForGame(uint256 tokenId, MercuryBase aviation) internal virtual {
        require(componentIndex().isValidAviation(address(aviation)), "MercuryGameBase: aviation is not valid");
        require(isApprovedForGame(tokenId, aviation), "MercuryGameBase: caller is not token owner or approved");
        aviation.aviationUnlock(tokenId);
        delete LibGameBase.layout().gameApprovals[tokenId];
        delete LibGameBase.layout().burnerAddressToTokenId[msg.sender];
        delete LibGameBase.layout().burnerAddressToAviation[msg.sender];
    }

    /*//////////////////////////////////////////////////////////////
                            Utils Function
    //////////////////////////////////////////////////////////////*/

    function setProtocol(address _protocol) public {
        LibDiamond.enforceIsContractOwner();
        LibGameBase.layout().protocol = _protocol;
    }

    function componentIndex() internal view returns (ComponentIndex) {
        return ComponentIndex(LibGameBase.protocol());
    }

    function burnerAddressToTokenId(address burner) public view returns (uint256) {
        return LibGameBase.burnerAddressToTokenId(burner);
    }

    function burnerAddressToAviation(address burner) public view returns (address) {
        return LibGameBase.burnerAddressToAviation(burner);
    }

    function isIdenticalAviation(address player1, address player2) internal view returns (bool) {
        return burnerAddressToAviation(player1) == burnerAddressToAviation(player2);
    }
}
