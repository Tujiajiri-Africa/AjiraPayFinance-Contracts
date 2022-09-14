// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';

contract MockAjiraPay is ERC1363{
    constructor() ERC20("Ajira Pay","AJP"){
        _mint(msg.sender, 200_000_000 * 1e18);
    }
    
}