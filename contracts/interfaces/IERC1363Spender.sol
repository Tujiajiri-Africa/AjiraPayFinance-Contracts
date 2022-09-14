// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC1363Spender {
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}
