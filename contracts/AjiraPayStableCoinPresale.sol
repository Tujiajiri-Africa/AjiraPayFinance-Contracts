// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';

contract AjiraPayStableCoinPresale is Ownable, AccessControl,ReentrancyGuard{
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

    address public immutable DAI;
    address public immutable BUSD;
    address public immutable USDT;
    address public immutable USDC;

    address payable public treasury;

    IERC20 public AjiraPayFinanceToken;

    AggregatorV3Interface internal busdPriceFeed;
    AggregatorV3Interface internal daiPriceFeed;
    AggregatorV3Interface internal usdtPriceFeed;
    AggregatorV3Interface internal usdcPriceFeed;
    AggregatorV3Interface internal bnbPriceFeed;

    event Contribute(address indexed beneficiary, uint indexed weiAmount, uint indexed tokenAmountBought, uint timestamp);
    event Claim(address indexed beneficiary, uint indexed tokenAmountReceived, uint indexed timestamp);
    event UpdateTreasury(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event RecoverBNB(address indexed caller, address indexed destinationWallet, uint indexed amount, uint timestamp);
    event RecoverERC20Tokens(address indexed caller, address indexed destination, uint amount, uint timestamp);

    constructor() {
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
        BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        USDT = 0x55d398326f99059fF775485246999027B3197955;
        USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

        AjiraPayFinanceToken = IERC20(0xC55b03dC07EC7Bb8B891100E927E982540f0d181);

        
        busdPriceFeed = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);
        daiPriceFeed  =  AggregatorV3Interface(0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA);
        usdtPriceFeed = AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);
        usdcPriceFeed = AggregatorV3Interface(0x51597f405303C4377E36123cBc172b13269EA163);
    }

    function contribute(address _stableCoin, uint _amount) public nonReentrant{
        require(_stableCoin != address(0),"Invalid Payment Address");
        require(_stableCoin == DAI || _stableCoin == USDC || _stableCoin == USDT || _stableCoin == BUSD,"Not a Payment method");
        require(_stableCoin != address(AjiraPayFinanceToken),"Invalid Payment Address");
        
       (AggregatorV3Interface priceFeed) =  _getPriceFeedFromAddress(_stableCoin);
       (uint256 price, uint256 decimals) = _getLatestStableCoinPriceInUSD(priceFeed);
       IERC20 paymentCoin = IERC20(_stableCoin);
       paymentCoin.safeTransferFrom(msg.sender, treasury, _amount);
       //emit Contribute(msg.sender, weiAmount, tokenAmountBought, timestamp);
    }

    function clain() public nonReentrant{

    }

    function UpdateTreasury(address payable _newTreasury) public onlyRole(MANAGER_ROLE){

    }

    function recoverERC20() public onlyRole(MANAGER_ROLE){

    }

    function recoverLostFundsForInvestor() public onlyRole(MANAGER_ROLE){

    }

    receive() external payable{}

    function _getPriceFeedFromAddress(address _stableCoin) private view returns(AggregatorV3Interface){
        if(_stableCoin == DAI){
            return daiPriceFeed;
        }else if(_stableCoin == BUSD){
            return busdPriceFeed;
        }else if(_stableCoin == USDT){
            return usdtPriceFeed;
        }else if(_stableCoin == USDC){
            return usdcPriceFeed;
        }else{
            return bnbPriceFeed;
        }
    }

    function _getLatestStableCoinPriceInUSD(AggregatorV3Interface _priceFeed) private view returns(uint256, uint256){
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        uint256 decimals = _priceFeed.decimals();
        return (uint256(price), decimals);
    }

    
}