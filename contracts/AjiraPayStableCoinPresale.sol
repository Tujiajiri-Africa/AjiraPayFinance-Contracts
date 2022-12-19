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
    IERC20 public immutable DAI;
    IERC20 public immutable BUSD;
    IERC20 public immutable USDT;
    IERC20 public immutable USDC;
    IERC20 public AjiraPayFinanceToken;

    constructor() {
        DAI = IERC20(0x1AF3F329e8BE154074D8769D1FFa4eE058B1DBc3);
        BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
        USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
        AjiraPayFinanceToken = IERC20(0xC55b03dC07EC7Bb8B891100E927E982540f0d181);
    }

    

}