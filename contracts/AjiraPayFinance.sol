// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract AjiraPayFinance is Ownable, ERC1363, ERC20Burnable{
    string private _name = "Ajira Pay Finance";
    string private _symbol = "AJP";
    uint256 private _totalSupply = 200_000_000 * 1e18;

    constructor() ERC20(_name, _symbol){
        _mint(msg.sender, _totalSupply);
    }
}