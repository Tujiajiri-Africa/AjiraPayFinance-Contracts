// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract AjiraPayManager is Ownable, AccessControl, ReentrancyGuard{
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    address payable public devTreasury;
    address payable public marketingTreasury;
    address payable public ajiraPayTreasury;

    uint256 public devTreasuryFeePercent = 1;
    uint256 public marketingTreasuryFeePercent = 1;

    bool isInTaxHolidayPhase = false;

    event NewDevTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event NewMarketingTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event ERC20TokenRecovered(address indexed token, address indexed beneficiary, uint indexed amount,uint timestamp);
    event TreasuryUpdated(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event TaxHolidayDeActivated(address indexed caller, uint indexed timestamp);
    event EthWithdrawal(address indexed caller, uint indexed amount, uint indexed timestamp);
    event NewDevTreasuryFee(address indexed caller, uint indexed newDevTreasuryFee, uint timestamp);
    event NewMarketingTreasuryFee(address indexed caller, uint indexed newMarketingTresuryFee, uint indexed timestamp);

    modifier nonZeroAddress(address _account){
        require(_account != address(0), "Ajira Pay: Zero Address detected");
        _;
    }

    modifier inTaxHolidayPhase(){
        require(isInTaxHolidayPhase == true,"Ajira Pay: Tax Holiday Not Active");
        _;
    }

    modifier isNotInTaxHolidayPhase(){
        require(isInTaxHolidayPhase == false,"Ajira Pay: Tax Holiday Active");
        _;
    }

    constructor(){
        _grantRole(MANAGER_ROLE, _msgSender());
        ajiraPayTreasury = payable(_msgSender());
    }

    function setDevTreasury(address payable _devTreasury) public onlyRole(MANAGER_ROLE) nonZeroAddress(_devTreasury) {
        if(_devTreasury == devTreasury) return;
        devTreasury = _devTreasury;
        emit NewDevTreasury(_devTreasury, msg.sender, block.timestamp);
    }

    function setMarketingTreasury(address payable _marketingTreasury) public onlyRole(MANAGER_ROLE) nonZeroAddress(_marketingTreasury){
        if(_marketingTreasury == marketingTreasury) return;
        marketingTreasury = _marketingTreasury;
        emit NewMarketingTreasury(_marketingTreasury, msg.sender, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, uint _amount) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(_token != address(this), "Ajira Pay: Unauthorized");
        if (_token == address(0x0)) {
            ajiraPayTreasury.transfer(address(this).balance);
            return;
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ERC20TokenRecovered(_token, msg.sender, _amount, block.timestamp);
    }

    function recoverBNB(uint _amount) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(_amount >= address(this).balance,"Insufficient Balance");
        ajiraPayTreasury.transfer(_amount);
        emit EthWithdrawal(msg.sender, _amount, block.timestamp);
    }

    function updateTreasury(address _newTreasury) public nonZeroAddress(_newTreasury) onlyRole(MANAGER_ROLE){
        if(ajiraPayTreasury == payable(_newTreasury)) return;
        address payable prevTreasury = ajiraPayTreasury;
        ajiraPayTreasury = payable(_newTreasury);
        emit TreasuryUpdated(msg.sender, prevTreasury, _newTreasury, block.timestamp);
    }
    
    function activateTaxHoliday() public isNotInTaxHolidayPhase onlyRole(MANAGER_ROLE){
        isInTaxHolidayPhase = true;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    function deActivateTaxHoliday() public inTaxHolidayPhase onlyRole(MANAGER_ROLE){
        isInTaxHolidayPhase = false;
        emit TaxHolidayDeActivated(msg.sender, block.timestamp);
    }

    function setDevFee(uint _fee) public onlyRole(MANAGER_ROLE){
        require(_fee > 0, "Ajira Pay: Zero Amount");
        devTreasuryFeePercent = _fee;
        emit NewDevTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setMarketingFee(uint _fee) public onlyRole(MANAGER_ROLE){
        require(_fee > 0, "Ajira Pay: Zero Amount");
        marketingTreasuryFeePercent = _fee;
        emit NewMarketingTreasuryFee(msg.sender, _fee, block.timestamp);
    }

}