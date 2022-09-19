// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC1363Receiver {
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}