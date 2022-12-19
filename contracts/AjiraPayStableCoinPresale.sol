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

    address public immutable DAI;
    address public immutable BUSD;
    address public immutable USDT;
    address public immutable USDC;
    IERC20 public AjiraPayFinanceToken;

    AggregatorV3Interface internal busdPriceFeed;
    AggregatorV3Interface internal daiPriceFeed;
    AggregatorV3Interface internal usdtPriceFeed;
    AggregatorV3Interface internal usdcPriceFeed;
    AggregatorV3Interface internal bnbPriceFeed;

    constructor() {
        DAI = 0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3;
        BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
        USDT = 0x55d398326f99059fF775485246999027B3197955;
        USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
        AjiraPayFinanceToken = IERC20(0xC55b03dC07EC7Bb8B891100E927E982540f0d181);

        
        busdPriceFeed = AggregatorV3Interface(0xcBb98864Ef56E9042e7d2efef76141f15731B82f);
        daiPriceFeed = AggregatorV3Interface(0x132d3C0B1D2cEa0BC552588063bdBb210FDeecfA);
        usdtPriceFeed = AggregatorV3Interface(0xB97Ad0E74fa7d920791E90258A6E2085088b4320);
        usdcPriceFeed = AggregatorV3Interface(0x51597f405303C4377E36123cBc172b13269EA163);
    }

    function stableCoinPurchase(address _stableCoin, uint _amount) public nonReentrant{
        //(address _priceFeedAddress) = _getPriceFeedFromAddress(_stableCoin);
        
    }

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

    function _getLatestBUSDPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = busdPriceFeed.latestRoundData();
        uint256 decimals = busdPriceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _getLatestUSDTPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = usdtPriceFeed.latestRoundData();
        uint256 decimals = usdtPriceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _getLatestDAIPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = daiPriceFeed.latestRoundData();
        uint256 decimals = daiPriceFeed.decimals();
        return (uint256(price), decimals);
    }

    function _getLatestUSDCPriceInUSD() private view returns(uint256, uint256){
        (, int256 price, , , ) = usdcPriceFeed.latestRoundData();
        uint256 decimals = usdcPriceFeed.decimals();
        return (uint256(price), decimals);
    }
}