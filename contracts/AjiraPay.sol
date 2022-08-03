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
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

// Import this file to use console.log
import "hardhat/console.sol";


contract AjiraPay is Ownable,AccessControl,ReentrancyGuard, IERC20{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    address public devTreasury;
    address public marketingTreasury;

    uint public devTreasuryFee;
    uint public marketingTreasuryFee;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    modifier nonZeroAddress(address _account){
        require(_account != address(0), "Ajira Pay: Zero Address detected");
        _;
    }

    event NewDevTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event NewMarketingTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event NewDevTreasuryFee(address indexed caller, uint indexed newDevTreasuryFee, uint timestamp);
    event NewMarketingTreasuryFee(address indexed caller, uint indexed newMarketingTresuryFee, uint indexed timestamp);

    constructor(address _router, address payable _devTreasury, address payable _marketingTreasury){
        require(_router != address(0),"Ajira Pay: Zero Address detected");
        require(_devTreasury != address(0),"Ajira Pay: Zero Address detected");
        require(_marketingTreasury != address(0),"Ajira Pay: Zero Address detected");

        _name = 'Ajira Pay';
        _symbol = 'AJP';
        _decimals = 18;
        _totalSupply = 200_000_000 * 10 ** _decimals;
        balances[msg.sender] = _totalSupply;

        devTreasury = _devTreasury;
        marketingTreasury = _marketingTreasury;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setDevTreasury(address payable _devTreasury) public nonZeroAddress(_devTreasury) onlyOwner{
        devTreasury = _devTreasury;
        emit NewDevTreasury(_devTreasury, msg.sender, block.timestamp);
    }

    function setMarketingTreasury(address payable _marketingTreasury) public nonZeroAddress(_marketingTreasury) onlyOwner{
        marketingTreasury = _marketingTreasury;
        emit NewMarketingTreasury(_marketingTreasury, msg.sender, block.timestamp);
    }

    function setDevFee(uint _fee) public onlyOwner{
        require(_fee > 0, "Ajira Pay: Dev Treasury Fee Cannot be zero or less");
        devTreasuryFee = _fee;
        emit NewDevTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setMarketingFee(uint _fee) public onlyOwner{
        require(_fee > 0, "Ajira Pay: Marketing Treasury Fee Cannot be zero or less");
        marketingTreasuryFee= _fee;
        emit NewMarketingTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function activateTaxHoliday() public onlyOwner{
        devTreasuryFee = 0;
        marketingTreasuryFee = 0;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    receive() external payable{}

    //recover tokens sent to this address by investor wrongfully, upon request 
    function recoverLostTokensForInvestor(address _token, uint _amount) public onlyOwner{
        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, _amount);
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function decimals() public view returns(uint){
        return _decimals;
    }

    function totalSupply() external view override returns(uint){
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint){
        return balances[account];
    }
}