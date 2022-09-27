// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import './AjiraPayManager.sol';

contract AjiraPayWhiteList is AjiraPayManager {
    mapping(address => bool) public isWhiteListedMerchant;
    mapping(address => bool) public isBlacklistedAddress;

    event NewBlackListAction(address indexed caller, address indexed blackListedAccount, uint timestamp);
    event AccountRemovedFromBlackList(address indexed caller, address indexed blackListedAccount, uint timestamp);
    event NewMerchantWhiteListed(address indexed caller, address indexed merchantAccount, uint indexed timestamp);
    event MerchantDelisted(address indexed caller, address indexed merchantAccount, uint timestamp);

    address[] public whiteListedMerchants;

    modifier merchantIsWhiteListed(address _merchant){
        require(isWhiteListedMerchant[_merchant] == true,"Ajira Pay: Merchant not Listed");
        _;
    }

    modifier merchantNotWhiteListed(address _merchant){
        require(isWhiteListedMerchant[_merchant] == false,"Ajira Pay: Merchant is Listed");
        _;
    }

    modifier isNotBlackListed(address _account){
        require(isBlacklistedAddress[_account] == false,"Ajira Pay: Account Blacklisted");
        _;
    }

    constructor(){}

    function whiteListMerchant(address _merchant) public onlyRole(MANAGER_ROLE) nonZeroAddress(_merchant) merchantNotWhiteListed(_merchant) returns(bool){
        isWhiteListedMerchant[_merchant] = true;
        whiteListedMerchants.push(_merchant);
        emit NewMerchantWhiteListed(msg.sender, _merchant, block.timestamp);
        return true;
    }

    function deListMerchant(address _merchant) public onlyRole(MANAGER_ROLE) nonZeroAddress(_merchant) merchantIsWhiteListed(_merchant)  returns(bool){
        isWhiteListedMerchant[_merchant] = false;
        emit MerchantDelisted(msg.sender, _merchant, block.timestamp);
        return true;
    }

    function addToBlackList(address _account) public onlyRole(MANAGER_ROLE) nonZeroAddress(_account)  returns(bool){
        isBlacklistedAddress[_account] = true;
        emit NewBlackListAction(msg.sender, _account, block.timestamp);
        return true;
    }

    function removeFromBlackList(address _account) public onlyRole(MANAGER_ROLE) nonZeroAddress(_account)  returns(bool){
        isBlacklistedAddress[_account] = false;
        emit AccountRemovedFromBlackList(msg.sender, _account, block.timestamp);
        return true;
    }


}