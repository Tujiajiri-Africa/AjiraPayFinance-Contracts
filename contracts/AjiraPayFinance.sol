// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';

contract AjiraPayFinance is Ownable, ERC1363, ReentrancyGuard,AccessControl{
    using SafeERC20 for IERC20;

    uint256 private _initialSupply = 200_000_000 * 1e18;
    string private _name = 'Ajira Pay Finance';
    string private _symbol = 'AJP';

    address payable public treasury;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    event ETHReceived(address indexed sender, uint indexed amount, uint indexed timestamp);
    event ERC20TokenRecovered(address indexed caller, address indexed recepient, uint indexed amount, uint timestamp);
    event TreasuryUpdated(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    
    constructor() ERC20(_name, _symbol){
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        _mint(msg.sender, _initialSupply);
        treasury = payable(msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1363, AccessControl) returns (bool) {
        return 
            interfaceId == type(IERC1363).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function recoverBNB(uint _amount) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(_amount >= address(this).balance,"Insufficient Balance");
        treasury.transfer(_amount);
    }

    // to help users who accidentally send their tokens to this contract
    function recoverTokens(address _token, address _account, uint256 _amount) public onlyRole(MANAGER_ROLE) nonReentrant{
        require(_token != address(this),"Invalid Token");
        IERC20(_token).safeTransfer(_account, _amount);
        emit ERC20TokenRecovered(msg.sender, _account, _amount, block.timestamp);
    }
    
    function updateTreasury(address _newTreasury) public onlyRole(MANAGER_ROLE){
        require(_newTreasury != address(0),"Invalid Address");
        if(treasury == _newTreasury) return;
        address prevTreasury = treasury;
        treasury = payable(_newTreasury);
        emit TreasuryUpdated(msg.sender, prevTreasury, _newTreasury, block.timestamp);
    }

    function totalEthBalance() public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable {
        emit ETHReceived(msg.sender, msg.value, block.timestamp);
    }
}