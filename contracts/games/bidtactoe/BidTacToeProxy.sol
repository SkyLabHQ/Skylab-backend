// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BidTacToeProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    
    //mumbai chain
    // address constant BidTacToePlayerVersusBot = address(0x7B390987D21F2b501f53aB6b08a17DC6C7f3FeD0);
    // address constant BidTacToe = address(0x6CdE2AD384a157D6eDE326886c70fb265F2CE9F9);
    
    //base goerli chain
    address constant BidTacToePlayerVersusBot = address(0xa6d4D07DfE8Fef7bcbfc7Bcf4C079C6e8719bf35);
    address constant BidTacToe = address(0x58cC8BE220a12C59E2Ba4e60B3Bf246D5BB824F8);
    
    // base mainnet
    // address constant BidTacToePlayerVersusBot = address(0x95780958eb0135805559d0d25EC14C81197E15D4);
    // address constant BidTacToe = address(0xD827b59aE7b13aD50Df9DC35c11e49496077F573);
    struct Address {
        address implementation;
    }

    function layout() private pure returns (Address storage impl) {
        bytes32 position = IMPLEMENTATION_SLOT;
        assembly {
            impl.slot := position
        }
    }

    constructor(bool isBot) {
        if (isBot) {
            layout().implementation = BidTacToePlayerVersusBot; // BidTacToePlayerVersusBot address
        } else {
            layout().implementation = BidTacToe; //BidTacToe address
        }
    }
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */

    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view returns (address) {
        return layout().implementation;
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}
