// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/token/ERC20/SolidStateERC20.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract Paper is SolidStateERC20 {
    uint256 public cap;
    address public leagueTournament;

    function initialize(uint8 _decimals, string memory _name, string memory _symbol,uint256 _cap, address _leagueTournament) public {
        LibDiamond.enforceIsContractOwner();
        _setName(_name);
        _setSymbol(_symbol);
        _setDecimals(_decimals);
        leagueTournament = _leagueTournament;
        cap = _cap;
    }

    function mint(address account, uint256 amount) public {
        require(_totalSupply() + amount <= cap, "Paper: exceed cap");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require(msg.sender == leagueTournament, "Paper: permission deny");
        _burn(account, amount);
    }
}