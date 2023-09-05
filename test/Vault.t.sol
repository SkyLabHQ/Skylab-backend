// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Vault} from "../contracts/Vault.sol";
import {SkylabBase} from "../contracts/SkylabBase.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract VaultTest is Test {
    Vault vault;
    SkylabBase base;

    function setUp() public {
        base = new SkylabBase("","","");
        vault = new Vault(base);
        base.setMintable(true);
    }

    function test_receiveNFT() public {
        base.mint(address(this));
        base.transferFrom(address(this), address(vault), 1);
        assertEq(base.ownerOf(1), address(vault));
    }

    function test_buyBack() public {
        vm.deal(address(this), 100 ether);
        base.mint(address(this));
        base.approve(address(vault), 1);
        vault.BuyBack(1);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    fallback() external {}
}
