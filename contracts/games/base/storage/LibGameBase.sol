// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibGameBase {
    bytes32 constant MERCURYGAMEBASE_STORAGE_POSITION = keccak256("diamond.standard.mercurygamebase.storage");

    struct MercuryGameBaseStorage {
        address protocol;
        // token id => address
        mapping(uint256 => address) gameApprovals;
        address contractOwner;
        // game  queue
        // collection to lobbies
        mapping(address => address[]) lobbyGameQueue;
        mapping(address => uint256) lobbyGameIndex;
        mapping(address => uint256) burnerAddressToTokenId;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function layout() internal pure returns (MercuryGameBaseStorage storage mgbs) {
        bytes32 position = MERCURYGAMEBASE_STORAGE_POSITION;
        assembly {
            mgbs.slot := position
        }
    }

    function burnerAddressToTokenId(address burner) internal view returns (uint256) {
        return layout().burnerAddressToTokenId[burner];
    }

    function protocol() internal view returns (address) {
        return layout().protocol;
    }

    function gameApprovals(uint256 tokenId) internal view returns (address) {
        return layout().gameApprovals[tokenId];
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = layout().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == layout().contractOwner, "LibDiamond: Must be contract owner");
    }

    function setContractOwner(address _newOwner) internal {
        MercuryGameBaseStorage storage mgbs = layout();
        address previousOwner = mgbs.contractOwner;
        mgbs.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function baseCreateLobby(address newGame, address collection) internal {
        layout().lobbyGameIndex[newGame] = layout().lobbyGameQueue[collection].length;
        layout().lobbyGameQueue[collection].push(newGame);
    }

    function baseJoinLobby(address lobby, address collection) internal {
        require(layout().lobbyGameIndex[lobby] != 0, "MercuryBidTacToe: lobby does not exist");
        address swappedLobby = layout().lobbyGameQueue[collection][layout().lobbyGameQueue[collection].length - 1];
        uint256 index = layout().lobbyGameIndex[lobby];
        layout().lobbyGameQueue[collection][index] = swappedLobby;
        layout().lobbyGameQueue[collection].pop();
        layout().lobbyGameIndex[swappedLobby] = index;
        delete layout().lobbyGameIndex[lobby];
    }
}
