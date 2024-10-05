// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VaultV2 {
    address public commissionReceiver;
    
    constructor(address _commissionReceiver) {
        commissionReceiver = _commissionReceiver;
    }

    function withdraw(uint256 value) external {
        payable(commissionReceiver).transfer(value);
    }

    receive() external payable {}
}
