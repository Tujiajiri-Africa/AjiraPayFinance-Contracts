// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AjiraPayFinancePrivateSale is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public ajiraPayToken;

    AggregatorV3Interface internal priceFeed;

    address payable public treasury;
    address private constant CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
    address private constant CHAINLINK_TESTNET_BNB_USD_PRICEFEED_ADDRESS = 0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526;

    address[] public investors;
    
    bool public isPresaleOpen = false;
    bool public isPresalePaused = false;
    bool public isOpenForClaims = false;
    
    uint public totalInvestors = 0;
    uint public presaleDurationInSec;
    uint public tokenDecimals = 18;
    uint public totalTokensSold = 0;
    uint public totalTokensClaimed = 0;
    uint public pricePerToken = 10 * 10** 18;
    uint public totalWeiRaised = 0;

    uint public maxTokenCapForPresale = 15_000_000 * 1e18;
    uint public maxTokensToPurchasePerWallet = 2000_000 * 1e18;
    uint public minTokensToPurchasePerWallet;

    uint public coolDown = (60 * 60 );
    
    uint private minUsdValuePerTokenDiviser = 400;
    uint public minUSDPricePerTokenFactor = 10000;
    uint public minUSDPricePerToken = minUsdValuePerTokenDiviser.div(minUSDPricePerTokenFactor);

    mapping(address => uint) public totalTokenContributionsByUser;
    mapping(address => uint) public totalTokenContributionsClaimedByUser;
    mapping(address => uint) public totalUnclaimedTokenContributionsByUser;
    mapping(address => uint) public totalBNBInvestmentsByIUser;
    mapping(address => bool) public hasClaimedRefund;
    mapping(address => bool) public canClaimTokens;
    mapping(address => bool) public isActiveInvestor;

    mapping(address => uint) public nextPossiblePurchaseTimeByUser;

    mapping(address => uint) public lastUserBuyTimeInSec; //store user's cooldown time to 1 minute

    event StartPresale(address indexed caller, uint indexed timestamp);
    event ClosePresale(address indexed caller, uint indexed timestamp);
    event PausePresale(address indexed caller, uint indexed timestamp);
    event UnpausePresale(address indexed caller, uint indexed timestamp);
    event Contribute(address indexed beneficiary, uint indexed weiAmount, uint indexed tokenAmountBought, uint timestamp);
    event Claim(address indexed beneficiary, uint indexed tokenAmountReceived, uint indexed timestamp);
    event UpdateTreasury(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event RecoverBNB(address indexed caller, address indexed destinationWallet, uint indexed amount, uint timestamp);
    event RecoverERC20Tokens(address indexed caller, address indexed destination, uint amount, uint timestamp);
    event UpdateMaxCap(address indexed caller, uint prevCap, uint newCap, uint timestamp);
    event ClaimUnsolTokens(address indexed caller, address indexed destination, uint indexed timestamp);

    modifier presaleOpen(){
        require(isPresaleOpen == true,"Sale Closed");
        _;
    }

    modifier presaleClosed(){
        require(isPresaleOpen == false,"Sale Open");
        _;
    }

    modifier presalePaused(){
        require(isPresalePaused == true,"Presale Not Paused");
        _;
    }

    modifier presaleUnpaused(){
        require(isPresalePaused == false,"Presale Paused");
        _;
    }

    modifier nonZeroAddress(address _account){
        require(_account != address(0),"Invalid Account");
        _;
    }

    modifier isEligibleForRefund(address contributor){
        require(hasClaimedRefund[contributor] == false,"Not eligible");
        _;
    }

    modifier isNotEligibleForRefund(address contributor){
        require(hasClaimedRefund[contributor] == true,"Refund Claimed Already");
        _;
    }

    modifier claimsOpen(){
        require(isOpenForClaims == true,"Claims Not Open");
        _;
    }

    constructor(address _token, address payable _treasury){
        require(_token != address(0),"Invalid Address");
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayToken = IERC20(_token); 
        treasury = _treasury;

        uint256 id = _getChainID();
        if(id == 56){
            priceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS);
        }else if(id == 97){
            priceFeed = AggregatorV3Interface(CHAINLINK_TESTNET_BNB_USD_PRICEFEED_ADDRESS);
        }
    }

    function startPresale() public onlyRole(MANAGER_ROLE) presaleClosed{
        isPresaleOpen = true;
        emit StartPresale(_msgSender(), block.timestamp);
    }

    function closePresale() public onlyRole(MANAGER_ROLE) presaleOpen{
        _setPresaleClosed();
        emit ClosePresale(_msgSender(), block.timestamp);
    }

    function pausePresale() public onlyRole(MANAGER_ROLE) presaleUnpaused{
        isPresalePaused = true;
        emit PausePresale(_msgSender(), block.timestamp);
    }

    function unpausePresale() public onlyRole(MANAGER_ROLE) presalePaused{
        isPresalePaused = false;
        emit UnpausePresale(_msgSender(), block.timestamp);
    }

    function activateTokenClaims() public onlyRole(MANAGER_ROLE){
        _setClaimStarted();
    }

    function deactivateTokenClaims() public onlyRole(MANAGER_ROLE){
        _setClaimsClosed();
    }

    function claimUnsoldTokens() public onlyRole(MANAGER_ROLE) presaleClosed nonReentrant{
        _refundUnsoldTokens(msg.sender);
        emit ClaimUnsolTokens(msg.sender, msg.sender, block.timestamp);
    }

    function updateTreasury(address payable _newTreasury) public onlyRole(MANAGER_ROLE) 
    nonZeroAddress(_newTreasury) 
    presalePaused
    {
        address payable prevTreasury = treasury;
        treasury = _newTreasury;
        emit UpdateTreasury(_msgSender(), prevTreasury, _newTreasury, block.timestamp);
    }

    function contribute() public payable nonReentrant presaleOpen{
        _checkUserCoolDownBeforeNextPurchase(msg.sender);
        uint256 weiAmount = msg.value;
        require(weiAmount > 0, "No Amount Specified");
        (uint256 price, uint256 decimals) = _getLatestBNBPriceInUSD();
        uint256 usdAmountFromValue = weiAmount.mul(price).div(10 ** decimals);
        uint256 tokenAmount = usdAmountFromValue.mul(100).mul(10**18).div(pricePerToken);
        uint256 totalTokensBoughtByUser = totalTokenContributionsByUser[msg.sender];
        require(totalTokensBoughtByUser + tokenAmount <= maxTokensToPurchasePerWallet,"Max Tokens Per Wallet Reached");
        require(tokenAmount < maxTokenCapForPresale,"Max Cap Reached");
        totalTokenContributionsByUser[msg.sender] = totalTokenContributionsByUser[msg.sender].add(tokenAmount);
        totalBNBInvestmentsByIUser[msg.sender] = totalBNBInvestmentsByIUser[msg.sender].add(weiAmount);
        totalTokensSold = totalTokensSold.add(tokenAmount);
        totalWeiRaised = totalWeiRaised.add(weiAmount);
        _updateInvestorCountAndStatus();
        _forwardFunds();
         if(totalTokensSold > maxTokenCapForPresale){
             _setPresaleClosed();
        }
        emit Contribute(msg.sender, weiAmount, tokenAmount, block.timestamp);
    }

    function claimContribution() public claimsOpen nonReentrant{
        require(canClaimTokens[msg.sender] == true,"Already Claimed Contribution");
        uint256 totalClaimableTokens = totalTokenContributionsByUser[msg.sender];
        require(totalClaimableTokens > 0,"Insufficient Token Claims");
        require(
            IERC20(ajiraPayToken).transfer(msg.sender, totalClaimableTokens),
            "Failed to send tokens"
        );
        totalTokenContributionsByUser[msg.sender] = 0;
        unchecked{
            totalTokenContributionsClaimedByUser[msg.sender] = totalTokenContributionsClaimedByUser[msg.sender].add(totalClaimableTokens);
            totalTokensClaimed = totalTokensClaimed.add(totalClaimableTokens);
        }
        canClaimTokens[msg.sender] = false;
        emit Claim(msg.sender, totalClaimableTokens, block.timestamp);
    }

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonReentrant{
        uint256 balance = getContractBNBBalance();
        require(balance > 0,"Insufficient Contract Balance");
        treasury.transfer(balance);
        emit RecoverBNB(msg.sender, treasury, balance, block.timestamp);
    }

    function recoverLostTokensForInvestor(address _token, address _account, uint _amount) public 
    nonReentrant nonZeroAddress(_token) nonZeroAddress(_account){
        IERC20 token = IERC20(_token);
        require(token != ajiraPayToken,"Invalid Token");
        token.safeTransfer(_account, _amount);
        emit RecoverERC20Tokens(_msgSender(), _account, _amount, block.timestamp);
    }

    function getContractTokenBalance() public view returns(uint256){
        return ajiraPayToken.balanceOf(address(this));
    }

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    function updateMaxTokenCapForPresale(uint256 _amount) public onlyRole(MANAGER_ROLE){
        require(_amount > 15_000_000,"Max Cap Must be above 15% of total supply");
        uint256 prevMaxCap = maxTokenCapForPresale;
        uint256 newMaxCap = _amount * 1e18;
        maxTokenCapForPresale = newMaxCap;
        emit UpdateMaxCap(msg.sender, prevMaxCap, newMaxCap, block.timestamp);
    }

    receive() external payable{
        contribute();
    }

    //INTERNAL HELPER FUNCTIONS
    function _getLatestBNBPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _forwardFunds() private{
        treasury.transfer(msg.value);
    }

    function _refundUnsoldTokens(address _destination) private{
        uint256 availableTokenBalance = getContractTokenBalance();
        uint256 refundableBalance = availableTokenBalance.sub(totalTokensSold);
        require(refundableBalance >= availableTokenBalance,"Insufficient Token Balance");
        require(ajiraPayToken.transfer(_destination, refundableBalance),"Failed To Refund Tokens");
    }

    function _checkUserCoolDownBeforeNextPurchase(address _account) private view{
        uint256 nextPurchaseTime = nextPossiblePurchaseTimeByUser[_account];
        if(block.timestamp < nextPurchaseTime){
            require(block.timestamp >= nextPurchaseTime,"Wait For 2 Mins Before Next Purchase");
        }
    }

    function _setClaimStarted() private{
        isOpenForClaims = true;
    }

    function _setClaimsClosed() private{
        isOpenForClaims = false;
    }

    function _setPresaleClosed() private{
        isPresaleOpen = false;
    }

    function _updateInvestorCountAndStatus() private{
        if(isActiveInvestor[msg.sender] == false){
            totalInvestors = totalInvestors.add(1);
            investors.push(msg.sender);
        }else{
            isActiveInvestor[msg.sender] = true;
        }
        canClaimTokens[msg.sender] = true;
        nextPossiblePurchaseTimeByUser[msg.sender] = block.timestamp.add(120); //2mins
        lastUserBuyTimeInSec[msg.sender] = block.timestamp;
    }

    function _getChainID() private view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}