// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibGameBase {
    bytes32 constant MERCURYGAMEBASE_STORAGE_POSITION = keccak256("diamond.standard.mercurygamebase.storage");

    struct MercuryGameBaseStorage {
        address protocol;
        // aviation to lobbies game queue
        mapping(address => address[]) lobbyGameQueue;
        mapping(address => uint256) lobbyGameIndex;
        mapping(address => address[]) lobbyOnGoingGames;
        mapping(address => uint256) lobbyOnGoingGamesIndex;
        // token id => burner address
        mapping(uint256 => address) gameApprovals;
        mapping(address => uint256) burnerAddressToTokenId;
        mapping(address => address) burnerAddressToAviation;
    }

    function layout() internal pure returns (MercuryGameBaseStorage storage mgbs) {
        bytes32 position = MERCURYGAMEBASE_STORAGE_POSITION;
        assembly {
            mgbs.slot := position
        }
    }

    function lobbyOnGoingGames(address aviation) internal view returns (address[] memory) {
        return layout().lobbyOnGoingGames[aviation];
    }

    function burnerAddressToTokenId(address burner) internal view returns (uint256) {
        return layout().burnerAddressToTokenId[burner];
    }

    function burnerAddressToAviation(address burner) internal view returns (address) {
        return layout().burnerAddressToAviation[burner];
    }

    function protocol() internal view returns (address) {
        return layout().protocol;
    }

    function gameApprovals(uint256 tokenId) internal view returns (address) {
        return layout().gameApprovals[tokenId];
    }

    function baseCreateLobby(address newGame, address aviation) internal {
        layout().lobbyGameIndex[newGame] = layout().lobbyGameQueue[aviation].length;
        layout().lobbyGameQueue[aviation].push(newGame);
    }

    function baseJoinLobby(address lobby, address aviation) internal {
        address swappedLobby = layout().lobbyGameQueue[aviation][layout().lobbyGameQueue[aviation].length - 1];
        uint256 index = layout().lobbyGameIndex[lobby];
        layout().lobbyGameQueue[aviation][index] = swappedLobby;
        layout().lobbyGameQueue[aviation].pop();
        layout().lobbyGameIndex[swappedLobby] = index;
        delete layout().lobbyGameIndex[lobby];
        layout().lobbyOnGoingGamesIndex[lobby] = layout().lobbyOnGoingGames[aviation].length;
        layout().lobbyOnGoingGames[aviation].push(lobby);
    }

    function baseQuitLobby(address game, address aviation) internal {
        address swappedGame = layout().lobbyOnGoingGames[aviation][layout().lobbyOnGoingGames[aviation].length - 1];
        uint256 index = layout().lobbyOnGoingGamesIndex[game];
        layout().lobbyOnGoingGames[aviation][index] = swappedGame;
        layout().lobbyOnGoingGames[aviation].pop();
        layout().lobbyOnGoingGamesIndex[swappedGame] = index;
        delete layout().lobbyOnGoingGamesIndex[game];
    }
}
