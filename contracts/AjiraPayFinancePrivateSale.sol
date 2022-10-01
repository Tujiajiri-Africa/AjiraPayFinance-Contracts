// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
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
    address private immutable CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS = 0x14e613AC84a31f709eadbdF89C6CC390fDc9540A;

    bool public isPresaleOpen = false;
    bool public isPresalePaused = false;

    uint public totalBNBraised;
    uint public minTokensToPurchasePerWallet;
    uint public maxTokensToPurchasePerWallet;
    uint public presaleDurationInSec;

    mapping(address => uint) public totalTokenContributionsByUser;
    mapping(address => uint) public totalTokenContributionsClaimedByUser;
    mapping(address => uint) public totalUnclaimedTokenContributionsByUser;
    mapping(address => uint) public totalBNBInvestmentsByIUser;
    mapping(address => bool) public hasClaimedRefund;

    event PresaleOpened(address indexed caller, uint indexed timestamp);
    event PresaleClosed(address indexed caller, uint indexed timestamp);
    event PresalePaused(address indexed caller, uint indexed timestamp);
    event PresaleUnpaused(address indexed caller, uint indexed timestamp);
    event Contribute(address indexed beneficiary, uint indexed weiAmount, uint indexed tokenAmountBought, uint timestamp);
    event ClaimContribution(address indexed beneficiary, uint indexed tokenAmountReceived, uint indexed timestamp);
    event TreasuryUpdated(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event BNBRecovered(address indexed caller, address indexed destinationWallet, uint indexed amount, uint timestamp);
    event ERC20TokenRecovered(address indexed caller, address indexed destination, uint amount, uint timestamp);

    //if 1 token = 0.05$
    //run presale for 1 month
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

    constructor(address _token, uint _presaleDurationInSec){
        require(_token != address(0),"Invalid Address");
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayToken = IERC20(_token); 
        treasury = payable(_msgSender());
        priceFeed = AggregatorV3Interface(CHAINLINK_MAINNET_BNB_USD_PRICEFEED_ADDRESS);
        presaleDurationInSec = _presaleDurationInSec;
    }

    function startPresale() public onlyRole(MANAGER_ROLE) presaleClosed{
        isPresaleOpen = true;
        emit PresaleOpened(_msgSender(), block.timestamp);
    }

    function closePresale() public onlyRole(MANAGER_ROLE) presaleOpen{
        isPresaleOpen = false;
        emit PresaleClosed(_msgSender(), block.timestamp);
    }

    function pausePresale() public onlyRole(MANAGER_ROLE) presaleUnpaused{
        isPresalePaused = true;
        emit PresalePaused(_msgSender(), block.timestamp);
    }

    function unpausePresale() public onlyRole(MANAGER_ROLE) presalePaused{
        isPresalePaused = false;
        emit PresaleUnpaused(_msgSender(), block.timestamp);
    }

    function updateTreasury(address _newTreasury) public onlyRole(MANAGER_ROLE) nonZeroAddress(_newTreasury) presalePaused{
        
    }

    function contribute() public payable nonReentrant{

    }

    function claimContribution() public nonReentrant{

    }

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonReentrant{
        treasury.transfer(address(this).balance);
    }

    function recoverLostTokensForInvestor(address _account, uint _amount) public nonReentrant{

    }

    function claimRefund() public nonReentrant{

    }

    function getContractTokenBalance() public view returns(uint256){
        return ajiraPayToken.balanceOf(address(this));
    }

    function getContractBNBBalance() public view returns(uint256){
        return address(this).balance;
    }

    receive() external payable{
        contribute();
    }

    //INTERNAL HELPER FUNCTIONS
    function _getLatestBNBPriceInUSD() private view returns(int256){
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function _forwardFunds() private{

    }

    function _refundUnsoldTokens() private{

    }
}