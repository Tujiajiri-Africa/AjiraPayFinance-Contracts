// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

contract AjiraPayFinanceStaking is Ownable, AccessControl, Pausable, ReentrancyGuard{
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public ajiraPayFinanceToken;

    Counters.Counter private stakeIds;
    Counters.Counter private stakeTierIds;

    uint256 public totalStakedTokens = 0;
    uint256 public totalStakeClaimed = 0;
    uint256 public totalStakingRewardsDistributed = 0;
    uint256 public totalStakingInvestors = 0;
    uint256 public minStake = 10 * 1e18;
    uint256 public maxStake = 100_000 * 1e18;
    uint256 public minStakingPeriod = 7 days;
    uint256 public maxStakingPeriod = 365 days;

    uint256 constant private MAX_INT_TYPE = type(uint256).max;

    address[] public stakers;
    address payable public treasury;

    mapping(address => uint256) public totalStakedByHolder;
    mapping(address =>mapping(uint256 => bool)) public isStakeWithdrawn;
    mapping(address => bool) public isActiveStaker;
    mapping(uint256 => bool) public stakingItemIdExists;

    mapping(uint256 => StakeTier) public stakingTierById;
    mapping(uint256 => NewStake) public stakingItemById;
    mapping(address => NewStake[]) public userStakeItems;

    struct NewStake{
        uint256 id;
        uint256 stakingAmount;
        uint256 stakedAt;
        uint256 stakeDuration;
        uint256 deadline;
        uint256 apr;
        address payable tokenHolder;
        address payable beneficiary;
    }

    struct StakeTier{
        uint256 id;
        uint256 apr;
        uint256 deadlineInDays;
        uint256 creationTimestamp;
        address creatorAccount;
        bool isPaused;
    }
    
    StakeTier[] public stakingTiers;
    NewStake[] public stakeItems;

    event Stake(
        uint256 stakeId, 
        address indexed beneficiary, 
        uint256 indexed stakedAmount, 
        uint256 apr,
        uint256 indexed stakeDeadLine,
        uint256 stakedAt
    );

    event StakingTierAdded(
        address indexed creatorAccount, 
        uint256 indexed tierId,
        uint256 indexed apr, 
        uint256 deadline,
        uint256 creationTimestamp
    );
    
    event WithdrawSingleStake(
        address indexed beneficiary, 
        uint256 indexed totalPreviousStake,
        uint256 indexed totalWithdrawnAmount, 
        uint256 timestamp
    );

    event UpdateToken(
        address indexed caller,
        address indexed token,
        uint256 indexed timestamp
    );

    event SetTierPauseStatus(
        address indexed caller,
        uint256 indexed tierId,
        bool indexed isTierPaused,
        uint256 timestamp
    );

    event EmmergencyWithdraw(
        address indexed staker,
        uint256 indexed tokenAmount,
        uint256 indexed timestamp
    );

    event RecoverERC20Tokens(
        address indexed beneficiary, 
        address indexed token,
        uint256 indexed tokenAmount,
        uint256 timestamp
    );

    event RecoveryTreasuryBal(
        address indexed caller,
        address indexed tokenDestination,
        uint256 indexed tokenAmount,
        uint256 timestamp
    );

    event SetStakingPeriod(
        address indexed caller,
        uint256 indexed minDurationInDays,
        uint256 indexed maxDurationInDays,
        uint256 timestamp
    );

    event HarvestReward(
        address indexed beneficiary,
        uint256 indexed tokenRewardAmount,
        uint256 indexed timestamp
    );

    event UpdateTreasury(
        address indexed caller,
        address payable indexed newTreasury,
        uint256 timestamp
    );
    
    event UpdateTierApr(
        address indexed caller,
        uint256 indexed tierId,
        uint256 indexed newApr,
        uint256 timestamp
    );

    modifier canClaimRewards(address _holder){
        require(isActiveStaker[_holder] == true,"AJP Staking: Not An Active Staker");
        _;
    }

    modifier hasNotClaimedStakeId(address _investor, uint256 _stakeId){
        require(isStakeWithdrawn[_investor][_stakeId] == false,"AJP Staking: Already Claimed Stake Item");
        _;
    }
    
    constructor(address _stakingToken, address payable _treasury){
        require(_stakingToken != address(0),"AJP Staking: Invalid staking token address");
        require(_treasury != address(0),"AJP Staking: Invalid Address");
        ajiraPayFinanceToken = IERC20(_stakingToken);
        _grantRole(MANAGER_ROLE, msg.sender);
        treasury = _treasury;

        ajiraPayFinanceToken.approve(address(this), MAX_INT_TYPE);
    }

    function stake(uint256 _amount, uint256 _stakingTierId) external whenNotPaused nonReentrant {
        require(_amount > 0, "AJP Staking: Zero Staking Amount Not Allowed");
        uint256 holderTokenBalance = ajiraPayFinanceToken.balanceOf(msg.sender);
        require(holderTokenBalance >= _amount,"AJP Staking: Insufficient balance for staking");

        uint256 holderStakedBalance = totalStakedByHolder[msg.sender];
        uint256 totalInvestorHoldings = _amount.mul(10 ** 18).add(holderStakedBalance);

        require(totalInvestorHoldings >= minStake,"AJP Staking: AJP Staking: Min Limit Per Wallet Reached");
        require(totalInvestorHoldings <= maxStake,"AJP Staking: Max Limit Per Wallet Reached");

        StakeTier storage _stakingTier = stakingTierById[_stakingTierId];

        require(_stakingTier.isPaused == false,"AJP Staking: Staking tier closed");

        stakeIds.increment();
        uint256 _currentStakeId = stakeIds.current();
        
        stakingItemById[_currentStakeId] = NewStake(
                _currentStakeId, 
                _amount,
                block.timestamp, 
                _stakingTier.deadlineInDays,
                block.timestamp.add(_stakingTier.deadlineInDays),
                _stakingTier.apr, 
                payable(msg.sender), 
                payable(msg.sender)
            );

        totalStakedTokens = totalStakedTokens.add(_amount);
        totalStakedByHolder[msg.sender] = totalStakedByHolder[msg.sender].add(_amount);

        if(!isActiveStaker[msg.sender]){
            isActiveStaker[msg.sender] = true;
            totalStakingInvestors = totalStakingInvestors.add(1);
            stakers.push(msg.sender);
        }
        stakingItemIdExists[_currentStakeId] = true;
        uint256 totalAmountInWei = _amount.mul(10 ** 18);
        _transferStakedTokens(msg.sender, totalAmountInWei);
        NewStake storage _stakeItem = stakingItemById[_currentStakeId];
        userStakeItems[msg.sender].push(_stakeItem);
        stakeItems.push(_stakeItem);
        emit Stake(_currentStakeId, _stakeItem.beneficiary, _amount, _stakeItem.apr, _stakeItem.stakeDuration, block.timestamp);
    }

    function withdrawSingleStake(uint256 _stakingId) external canClaimRewards(msg.sender) hasNotClaimedStakeId(msg.sender, _stakingId) whenNotPaused nonReentrant{
        require(stakingItemIdExists[_stakingId] == true,"AJP Staking: Non-Existent Staking Id");
        NewStake storage _stakeItem = stakingItemById[_stakingId];
        require(msg.sender == _stakeItem.beneficiary,"AJP Staking: Unauthorized claim");
        require(block.timestamp >= _stakeItem.deadline,"AJP Staking: Stake Not Matured");
        uint256 totalSupply = ajiraPayFinanceToken.balanceOf(address(this));
        uint256 stakeApr = _stakeItem.apr;
        uint256 _totalStakePeriodDiff = block.timestamp.sub(_stakeItem.stakedAt);
        uint256 amount = _stakeItem.stakingAmount;
        uint256 totalRewards = amount.mul(stakeApr).mul(_totalStakePeriodDiff).div(_stakeItem.stakeDuration).div(100);
        uint256 totalAccumulatedReward = amount.add(totalRewards);
        require(totalAccumulatedReward <= totalSupply,"AJP Staking: Insufficient Supply");
        uint256 totalTokenAmountInWei = totalAccumulatedReward * 10 ** 18;
        _withdraw(msg.sender,totalTokenAmountInWei);
        isStakeWithdrawn[msg.sender][_stakeItem.id] = true;
        totalStakedTokens = totalStakedTokens.sub(totalAccumulatedReward);
        totalStakeClaimed = totalStakeClaimed.add(totalAccumulatedReward);
        totalStakingRewardsDistributed = totalStakingRewardsDistributed.add(totalRewards);
        emit WithdrawSingleStake(msg.sender, amount, totalAccumulatedReward, block.timestamp);
    }

    function emmergencyWithdraw(uint256 _stakingId) external canClaimRewards(msg.sender) hasNotClaimedStakeId(msg.sender, _stakingId) whenNotPaused nonReentrant {
        require(stakingItemIdExists[_stakingId] == true,"AJP Staking: Non-Existent Staking Id");
        NewStake storage _stakeItem = stakingItemById[_stakingId];
        uint256 totals;
        uint256 totalRewards;
        require(msg.sender == _stakeItem.beneficiary,"AJP Staking: Unauthorized claim");
        uint256 totalSupply = ajiraPayFinanceToken.balanceOf(address(this));
        bool pastDeadLine = block.timestamp >= _stakeItem.deadline;
        if(pastDeadLine){
            uint256 stakeApr = _stakeItem.apr;
            uint256 _totalStakePeriodDiff = block.timestamp.sub(_stakeItem.stakedAt);
            uint256 amount = _stakeItem.stakingAmount;
            totalRewards = amount.mul(stakeApr).mul(_totalStakePeriodDiff).div(_stakeItem.stakeDuration).div(100);
            totals = amount.add(totalRewards);
        }else{
            totals = _stakeItem.stakingAmount;
            totalRewards = 0;
        }
        require(totals <= totalSupply,"AJP Staking: Insufficient Supply");
        uint256 totalsInWei = totals.mul(10 ** 18);
        _withdraw(msg.sender,totalsInWei);
        isStakeWithdrawn[msg.sender][_stakeItem.id] = true;
        totalStakedTokens = totalStakedTokens.sub(totals);
        totalStakeClaimed = totalStakeClaimed.add(totals);
        totalStakingRewardsDistributed = totalStakingRewardsDistributed.add(totalRewards);
        emit EmmergencyWithdraw(msg.sender, totals, block.timestamp);
    }

    function addStakingTier(uint56 _apr, uint256 _deadlineInDays) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_apr > 0,"AJP Staking: Invalid APR Value");
        require(_deadlineInDays >= 7 && _deadlineInDays <= 365, "AJP Staking: Invalid Staking Duration");
        require(_deadlineInDays.mul(1 days) >= minStakingPeriod && _deadlineInDays.mul(1 days) <= maxStakingPeriod,"AJP Staking: Invalid Duration");

        stakeTierIds.increment();

        uint256 currentTierId = stakeTierIds.current();
        uint256 deadlineInDays = _deadlineInDays.mul(1 days);
        
        stakingTierById[currentTierId] = StakeTier(currentTierId, _apr, deadlineInDays, block.timestamp, msg.sender, false);
        StakeTier storage _tier = stakingTierById[currentTierId];
        stakingTiers.push(_tier);
        emit StakingTierAdded(msg.sender, currentTierId, _apr, deadlineInDays, block.timestamp);
    }

    function updateStakingToken(address _token) external onlyRole(MANAGER_ROLE){
        require(_token != address(0),"AJP Staking: Token cannot be zero address");
        ajiraPayFinanceToken = IERC20(_token);
        emit UpdateToken(msg.sender, _token, block.timestamp);
    }

    function pause() external onlyRole(MANAGER_ROLE){
        _pause();
    }

    function unPause() external onlyRole(MANAGER_ROLE){
        _unpause();
    }

    function setTierPauseStatus(uint256 _tier, bool _isPaused) external onlyRole(MANAGER_ROLE){
        StakeTier storage _stakeTier = stakingTierById[_tier];
        _stakeTier.isPaused = _isPaused;
        emit SetTierPauseStatus(msg.sender, _stakeTier.id, _isPaused, block.timestamp);
    }

    function setMinMaxStakeAmount(uint256 _minAmount, uint256 _maxAmount) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_minAmount > 0,"AJP Staking: Min Stake Cannot be zero");
        require(_maxAmount > 0,"AJP Staking: Max Stake Cannot be zero");

        minStake = _minAmount * 1e18;
        maxStake = _maxAmount * 1e18;
    }

    function setMinMaxStakingPeriod(uint256 _minStakingDays, uint256 _maxStakingDays) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_minStakingDays > 0 && _minStakingDays.mul(1 days) <= maxStakingPeriod,"AJP Staking: Invalid Min Staking Duration");
        require(_maxStakingDays > 0 && _maxStakingDays.mul(1 days) >= minStakingPeriod,"AJP Staking: Invalid Max Staking Duration");

        minStakingPeriod = _minStakingDays.mul(1 days);
        maxStakingPeriod = _maxStakingDays.mul(1 days);
        emit SetStakingPeriod(msg.sender, minStakingPeriod, maxStakingPeriod, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, uint _amount) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_token != address(0),"AJP Staking: Invalid Token");
        IERC20 token = IERC20(_token);
        require(token != ajiraPayFinanceToken,"AJP Staking: Invalid Token");
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount,"AJP Staking: Insufficient token recover balance");
        token.safeTransfer(treasury, _amount);
        emit RecoverERC20Tokens(treasury, _token, _amount, block.timestamp);
    }

    function recoverTreasuryBalance() external onlyRole(MANAGER_ROLE) nonReentrant{
        uint256 balance = ajiraPayFinanceToken.balanceOf(address(this));
        uint256 tokensToWithdraw = balance.sub(totalStakedTokens);
        require(tokensToWithdraw > 0,"AJP Staking: Insufficient Treasury Balance");
        _withdraw(treasury, tokensToWithdraw);
        emit RecoveryTreasuryBal(msg.sender, treasury, tokensToWithdraw, block.timestamp);
    }

    function updateTierApr(uint256 _tierId, uint256 _newApr) external onlyRole(MANAGER_ROLE) nonReentrant{
        require(_newApr > 0,"AJP Staking: APR Cannot be 0%");
        StakeTier storage _stakeTier = stakingTierById[_tierId];
        _stakeTier.apr = _newApr;
        emit UpdateTierApr(msg.sender, _tierId, _newApr, block.timestamp);
    }

    function updateTreasury(address _treasury) external onlyRole(MANAGER_ROLE){
        require(_treasury != address(0),"AJP Staking: Invalid Treasury");
        treasury = payable(_treasury);
        emit UpdateTreasury(msg.sender,treasury, block.timestamp);
    } 

    function calculateReward(uint256 _stakingItemId) external view returns(uint256){
        NewStake storage _stakeItem = stakingItemById[_stakingItemId];
        uint256 rewards;
        if(isStakeWithdrawn[_stakeItem.beneficiary][_stakeItem.id] == true){
            rewards = 0;
        }if(block.timestamp < _stakeItem.deadline){
            rewards = 0;
        }
        else{
            uint256 _totalStakePeriodDiff = block.timestamp.sub(_stakeItem.stakedAt);
            uint256 duration = _stakeItem.stakeDuration;
            uint256 amount = _stakeItem.stakingAmount;
            uint256 stakeApr = _stakeItem.apr;
            rewards = amount.mul(stakeApr).mul(_totalStakePeriodDiff).div(duration).div(100);
        }
        return rewards;
    }

    function getTotalValueLocked() public view returns(uint256){
        return ajiraPayFinanceToken.balanceOf(address(this));
    }

    function _transferStakedTokens(address _holder, uint256 _amount) private{
        ajiraPayFinanceToken.safeTransferFrom(_holder, address(this), _amount);
    }

    function _withdraw(address _beneficiary, uint256 _amount) private{
        ajiraPayFinanceToken.safeTransfer(_beneficiary, _amount);
    }
}