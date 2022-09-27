// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract AjiraPayAirdropDistributor is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;

    IERC20 private token;

    bool public isAirdropActive = false;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    event AirdropActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event AirdropDeActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event RewardTokenSet(address indexed caller, IERC20 indexed token, uint timestamp);

    modifier isActive(){
        require(isAirdropActive == true,"Airdrop not active");
        _;
    }

    modifier isNotActive(){
        require(isAirdropActive == false,"Airdrop is active");
        _;
    }

    modifier nonZeroAddress(address _account){
        require(_account != address(0),"Invalid Account");
        _;
    }

    constructor(IERC20 _token){
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
        
        token = _token;
    }

    function activateAirdrop() public onlyRole(MANAGER_ROLE) isNotActive{
        emit AirdropActivated(_msgSender(), token, );
    }

    function deactivateAirdrop() public onlyRole(MANAGER_ROLE) isActive{

    }

    function distributeReward(address _beneficiary, uint _amount) public nonZeroAddress(_beneficiary) onlyRole(MANAGER_ROLE) isActive{

    }

    function setRewardToken(address _token) public nonZeroAddress(_token) onlyRole(MANAGER_ROLE){
        token = IERC20(_token);
        emit RewardTokenSet(_msgSender(), _token, block.timestamp);
    }

    function claimAirdrop() public{

    }
}