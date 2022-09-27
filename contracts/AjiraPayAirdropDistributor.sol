// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract AjiraPayAirdropDistributor is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;

    IERC20 public rewardToken;

    bool public isAirdropActive = false;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    mapping(address => uint) public userRewards;
    mapping(address => bool) public isExistingWinner;

    event AirdropActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event AirdropDeActivated(address indexed caller, IERC20 indexed token, uint indexed timestamp);
    event RewardTokenSet(address indexed caller, IERC20 indexed token, uint timestamp);
    event NewWinner(address indexed caller, address indexed winner, uint indexed amount, uint timestamp);
    event NewAirdropPayout(address indexed caller, address indexed beneciary, uint indexed amount, uint timestamp);

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
        
        rewardToken = _token;
    }

    function activateAirdrop() public onlyRole(MANAGER_ROLE) isNotActive{
        isAirdropActive = true;
        emit AirdropActivated(_msgSender(), rewardToken, block.timestamp);
    }

    function deactivateAirdrop() public onlyRole(MANAGER_ROLE) isActive{
        isAirdropActive = false;
        emit AirdropDeActivated(_msgSender(), rewardToken, block.timestamp);
    }

    function addWinner(address _winner, uint _amount) public nonZeroAddress(_winner) onlyRole(MANAGER_ROLE){
        require(_amount > 0,"Amount is zero");
        if(isExistingWinner[_winner] == false){ isExistingWinner[_winner] = true;}
        userRewards[_winner] = userRewards[_winner].add(_amount);
        emit NewWinner(_msgSender(), _winner, _amount, block.timestamp);
    }

    function distributeReward(address _beneficiary) public nonZeroAddress(_beneficiary) onlyRole(MANAGER_ROLE) isActive{
        require(isExistingWinner[_beneficiary] = true,"Not a beneficiary");
        uint rewardAmount = userRewards[_beneficiary];
        rewardToken.transfer(_beneficiary,rewardAmount);
        emit NewAirdropPayout(_msgSender(),_beneficiary, rewardAmount, block.timestamp);
    }

    function setRewardToken(address _token) public nonZeroAddress(_token) onlyRole(MANAGER_ROLE){
        rewardToken = IERC20(_token);
        emit RewardTokenSet(_msgSender(), rewardToken, block.timestamp);
    }

    function claimAirdrop() public{

    }
}