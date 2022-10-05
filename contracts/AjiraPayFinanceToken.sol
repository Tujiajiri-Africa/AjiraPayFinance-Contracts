// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

interface IPancakeswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IPancakeSwapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract AjiraPayFinanceToken is Ownable, ERC1363, ReentrancyGuard,AccessControl{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 private _totalSupply = 200_000_000 * 1e18;
    string private _name = 'Ajira Pay Finance';
    string private _symbol = 'AJP';

    address payable public treasury;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IPancakeRouter02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public isInTaxHoliday = false;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTx;

    uint256 public _buyFee;
    uint256 public _sellFee;

    uint256 public minLiquidityAmount; 
    uint256 public liquidityFee;
    uint256 private previousLiquidityFee = liquidityFee;
    uint256 public txFee;
    uint256 private previousTaxFee = txFee;
    uint256 public maxTransactionAmount;
    
    event ERC20TokenRecovered(address indexed caller, address indexed recepient, uint indexed amount, uint timestamp);
    event TreasuryUpdated(address indexed caller, address indexed prevTreasury, address indexed newTreasury, uint timestamp);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event RouterUpdated(address indexed caller, address indexed prevRouter, address indexed newRouter, uint timestamp);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event MaxTransactionUpdated(address indexed caller, uint256 indexed prevAmount, uint256 indexed newAmount, uint timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event TaxHolidayDeactivated(address indexed caller, uint indexed timestamp);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier notExcludedFromMaxTx(address _account){
        require(_isExcludedFromMaxTx[_account] == false,"Account Excluded");
        _;
    }

    modifier isInActiveTaxHoliday(){
        require(isInTaxHoliday == true,"Tax Holiday Inactive");
        _;
    }

    modifier isNotInActiveTaxHoliday(){
        require(isInTaxHoliday == false,"Tax Holiday Active");
        _;
    }

    constructor(address _router, address _treasury) ERC20(_name, _symbol){
        require(_router != address(0),"Invalid Address");
        require(_treasury != address(0),"Invalid Address");

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());

        treasury = payable(_treasury);

        IPancakeRouter02 _pancakeSwapV2Router = IPancakeRouter02(_router);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeSwapV2Router.factory()).createPair(
            address(this), 
            _pancakeSwapV2Router.WETH());

        pancakeswapV2Router = _pancakeSwapV2Router;

        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasury] = true;
        
        _isExcludedFromMaxTx[_msgSender()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[treasury] = true;

        _buyFee = 2;
        _sellFee = 5;
        txFee = 2;
        liquidityFee = 1;

        minLiquidityAmount = _totalSupply.div(1000).div(4); //50_000
        maxTransactionAmount = _totalSupply.div(200); //1000_000

        _mint(_msgSender(), _totalSupply);
        
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

    function recoverLostTokensForInvestor(address _token, uint _amount) public onlyRole(MANAGER_ROLE) nonReentrant {
        require(_token != address(this), "Invalid Token Address");
        if (_token == address(0x0)) {
            treasury.transfer(address(this).balance);
            return;
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ERC20TokenRecovered(_token, msg.sender, _amount, block.timestamp);
    }
    
    function updateTreasury(address _newTreasury) public onlyRole(MANAGER_ROLE){
        require(_newTreasury != address(0),"Invalid Address");
        if(treasury == payable(_newTreasury)) return;
        address payable prevTreasury = treasury;
        treasury = payable(_newTreasury);
        _isExcludedFromFee[treasury] = true;
        emit TreasuryUpdated(msg.sender, prevTreasury, _newTreasury, block.timestamp);
    }

    function totalEthBalance() public view returns(uint256){return address(this).balance;}

    function updateRouterAddress(address _newRouter) external onlyRole(MANAGER_ROLE) {
        require(_newRouter != address(0),"Invalid Router Address");
        IPancakeRouter02 prevRouter = pancakeswapV2Router;
        IPancakeRouter02 _pancakeSwapV2Router = IPancakeRouter02(_newRouter);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeSwapV2Router.factory()).createPair(address(this), _pancakeSwapV2Router.WETH()); 
        pancakeswapV2Router = _pancakeSwapV2Router;
        emit RouterUpdated(_msgSender(), address(prevRouter), _newRouter, block.timestamp);
    }

    function setTxFeePercentage(uint256 _txFee) external onlyRole(MANAGER_ROLE) {
        require(_txFee != 0,"Fee cannot be zero");
        txFee = _txFee;
    }

    function setLiquidityFeePercentage(uint256 _liquidityFee) external onlyRole(MANAGER_ROLE) {
        require(_liquidityFee != 0,"Fee cannot be zero");
        liquidityFee = _liquidityFee;
    }

    function setBuyFeePercentage(uint256 _fee) external onlyRole(MANAGER_ROLE){
        require(_fee != 0,"Fee cannot be zero");
        _buyFee = _fee;
    }

    function setSellFeePercentage(uint256 _fee) external onlyRole(MANAGER_ROLE){
        require(_fee != 0,"Fee cannot be zero");
        _sellFee = _fee;
    }

    function setSwapAndLiquifyEnabled() public onlyRole(MANAGER_ROLE)   {
        swapAndLiquifyEnabled = true;
        emit SwapAndLiquifyEnabledUpdated(true);
    }

    function excludeFromMaxTransaction(address _beneficiary) public onlyRole(MANAGER_ROLE){
        _isExcludedFromMaxTx[_beneficiary] = true;
    }

    function setMaxTransactionAmount(uint _amount) public onlyRole(MANAGER_ROLE){
        require(_amount != 0,"Zero Amt");
        require(_amount < _totalSupply.div(100));
        uint256 prevAmount = maxTransactionAmount;
        maxTransactionAmount = _amount;
        emit MaxTransactionUpdated(_msgSender(), prevAmount, _amount, block.timestamp);
    }

    function activateTaxHoliday() public onlyRole(MANAGER_ROLE) isNotInActiveTaxHoliday{
        isInTaxHoliday = true;
        emit TaxHolidayActivated(_msgSender(), block.timestamp);
    }
        
    function deActivateTaxHoliday() public onlyRole(MANAGER_ROLE) isInActiveTaxHoliday{
        isInTaxHoliday = false;
        emit TaxHolidayDeactivated(_msgSender(), block.timestamp);
    }

    receive() external payable {}

    //********************************** INTERNAL HELPER FUNCTIONS *********************************** */
    function _transfer(address _sender, address _recipient, uint _amount) internal virtual override {
        require(_sender != address(0), "Invalid Address");
        require(_recipient != address(0), "Invalid Address");
        _validateAmount(_sender, _recipient, _amount);

        uint256 senderBalance = balanceOf(_sender);

        require(senderBalance >= _amount, "insufficient Balance");

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= minLiquidityAmount;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            _sender != pancakeswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
                contractTokenBalance = minLiquidityAmount;
                _swapAndLiquify(contractTokenBalance);
            }

            bool takeFee = true;
            _isExcludedFromFee[_sender] == true ? takeFee = false : takeFee = true;
            _isExcludedFromFee[_recipient] == true ? takeFee = false : takeFee = true;
            isInTaxHoliday == true ? takeFee = false: takeFee = true;

            _transferStandard(_sender,_recipient,_amount,takeFee); 
    }

    function _transferStandard(address _sender, address _recipient, uint256 _amount, bool takeFee) private returns(bool success){
        uint256 senderBalance = balanceOf(_sender);
        uint256 recipientBalance = balanceOf(_recipient);

        senderBalance = senderBalance.sub(_amount);
        uint256 amountReceived = (takeFee) ? _takeTaxes(_sender, _recipient, _amount) : _amount;
        recipientBalance = recipientBalance.add(amountReceived);

        if(isInTaxHoliday == false){
            (,uint256 txFeeAmount,uint256 liquidityFeeAmount) = _getFeeAmountValues(_amount);
            _takeLiquidity(liquidityFeeAmount);
            _takeFee(txFeeAmount);
        }

        emit Transfer(_sender, _recipient, amountReceived);
        return true;
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
      uint256 half = contractTokenBalance.div(2);
      uint256 otherHalf = contractTokenBalance.sub(half);
      uint256 initialBalance = address(this).balance;

      _swapTokensForBnb(half); 

      uint256 newBalance = address(this).balance.sub(initialBalance);

      uint256 halfBalance = newBalance.div(2);
      _sendFeeToTreasury(treasury, halfBalance);
      uint256 remainingBalance = newBalance.sub(halfBalance);      
      _addLiquidity(otherHalf, remainingBalance);
      emit SwapAndLiquify(half, remainingBalance, otherHalf);
    }

    function _swapTokensForBnb(uint256 _tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), _tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        _tokenAmount,
        0, // accept any amount of BNB
        path,
        address(this),
        block.timestamp
        );
    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount) private{
        _approve(address(this), address(pancakeswapV2Router), _tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: _bnbAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(liquidityFee).div(10**2);
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(txFee).div(10**2);
    }

    function _getFeeAmountValues(uint256 _tAmount) private view returns (uint256, uint256, uint256) {
      uint256 tFee = _calculateTaxFee(_tAmount);
      uint256 tLiquidity = _calculateLiquidityFee(_tAmount);
      uint256 tTransferAmount = _tAmount.sub(tFee).sub(tLiquidity);
      return (tTransferAmount, tFee, tLiquidity);
    }

    function _takeLiquidity(uint256 _liquidityFeeAmount) private view {
        uint256 contractBalance = balanceOf(address(this));
        contractBalance = contractBalance.add(_liquidityFeeAmount);
    }

    function _takeFee(uint256 _taxFeeAmount) private view{
        uint256 contractBalance = balanceOf(address(this));
        contractBalance = contractBalance.add(_taxFeeAmount);
    }

    function _takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 contractBalance = balanceOf(address(this));
        uint256 currentFee;
        if (from == pancakeswapV2Pair) {
            currentFee = _buyFee;
        } else if (to == pancakeswapV2Pair) {
            currentFee = _sellFee;
        } else {
            currentFee = txFee;
        }

        uint256 feeAmount = amount.mul(currentFee).div(10000);
        contractBalance = contractBalance.add(feeAmount);
        emit Transfer(from, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function _sendFeeToTreasury(address _treasury, uint256 _amount) private{
        payable(_treasury).transfer(_amount);
    }

    function _validateAmount(address _sender, address _recipient, uint256 _amount) private view{
        if(_amount > maxTransactionAmount){
            if(_isExcludedFromMaxTx[_sender] == false || _isExcludedFromMaxTx[_recipient] == false){
                require(_amount <= maxTransactionAmount,"Max Tx Exceeded");
            }
        }
    }
}