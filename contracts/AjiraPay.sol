// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

// Import this file to use console.log
import "hardhat/console.sol";


contract AjiraPay is Ownable,AccessControl,ReentrancyGuard, IERC20{
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    constructor(){
        _name = 'Ajira Pay';
        _symbol = 'AJP';
        _decimals = 18;
        _totalSupply = 200_000_000 * 10 ** _decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
}