// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
//import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import 'erc-payable-token/contracts/token/ERC1363/IERC1363.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Address.sol';

// Import this file to use console.log
import "hardhat/console.sol";

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

interface IERC1363Spender {
    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC1363Receiver {
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);
}

contract AjiraPay is Ownable,ReentrancyGuard, IERC1363Spender, IERC1363Receiver, ERC165,AccessControl, IERC1363{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    using Address for address;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    address payable public devTreasury;
    address payable public marketingTreasury;

    uint public devTreasuryFeePercent = 1;
    uint public marketingTreasuryFeePercent = 1;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    mapping(address => bool) public excludedFromFee;
    mapping(address => bool) public isBlacklistedAddress;

    mapping(address => bool) public isWhiteListedMerchant;
    address[] public whiteListedMerchants;

    bool isInTaxHolidayPhase = false;

    IPancakeRouter02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public minimumTokensBeforeSwap;
    uint256 public maxTxAmount;

    uint public constant MAX_FEE_FACTOR = 100;
    uint public liquidityPoolFactor;

    modifier nonZeroAddress(address _account){
        require(_account != address(0), "Ajira Pay: Zero Address detected");
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyManager(address _account){
        require(hasRole(MANAGER_ROLE, _account),"Ajira Pay: An unauthorized account");
        _;
    }

    event NewDevTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event NewMarketingTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event NewDevTreasuryFee(address indexed caller, uint indexed newDevTreasuryFee, uint timestamp);
    event NewMarketingTreasuryFee(address indexed caller, uint indexed newMarketingTresuryFee, uint indexed timestamp);
    event EthWithdrawal(address indexed caller, uint indexed amount, uint indexed timestamp);
    event NewRouterAddressSet(address indexed caller, address indexed newAddress, uint indexed timestamp);
    event ExcludeFromFee(address indexed caller, address indexed account, uint timestamp);
    event IncludeInFee(address indexed caller, address indexed account, uint timestamp);
    event ERC20TokenRecovered(address indexed token, address indexed beneficiary, uint indexed amount,uint timestamp);
    event NewBlackListAction(address indexed caller, address indexed blackListedAccount, uint timestamp);
    event AccountRemovedFromBlackList(address indexed caller, address indexed blackListedAccount, uint timestamp);
    event NewMerchantWhiteListed(address indexed caller, address indexed merchantAccount, uint indexed timestamp);
    event MerchantDelisted(address indexed caller, address indexed merchantAccount, uint timestamp);
    event MinLiquidityAmountUpdated(address indexed caller, uint newAmount, uint indexed timestamp);
    event SwapAndLiquidify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event NewLiquidityFeeFactor(address caller, uint newFeeFactor, uint timestamp);

    constructor(address _router){
        require(_router != address(0),"Ajira Pay: Zero Address detected");

        _setupRole(MANAGER_ROLE, _msgSender());

        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(_router);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        pancakeswapV2Router = _pancakeswapV2Router;

        excludedFromFee[msg.sender] = true;
        excludedFromFee[pancakeswapV2Pair] = true;
        excludedFromFee[address(this)] = true;
        excludedFromFee[devTreasury] = true;
        excludedFromFee[marketingTreasury] = true;

        _name = 'Ajira Pay';
        _symbol = 'AJP';
        _decimals = 18;
        _totalSupply = 200_000_000 * (10 ** _decimals);
        
        liquidityPoolFactor = 100000;
        minimumTokensBeforeSwap = _totalSupply.div(liquidityPoolFactor);
        //maxTxAmount = 5000_000 * 10** _decimals;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC1363Spender).interfaceId ||
            interfaceId == type(IERC1363Receiver).interfaceId ||
            interfaceId == type(IERC1363).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setDevTreasury(address payable _devTreasury) public 
    nonZeroAddress(_devTreasury) 
    onlyManager(msg.sender)
    {
        if(_devTreasury == devTreasury) return;
        devTreasury = _devTreasury;
        emit NewDevTreasury(_devTreasury, msg.sender, block.timestamp);
    }

    function setMarketingTreasury(address payable _marketingTreasury) public 
    nonZeroAddress(_marketingTreasury)
    onlyManager(msg.sender)
    {
        if(_marketingTreasury == marketingTreasury) return;
        marketingTreasury = _marketingTreasury;
        emit NewMarketingTreasury(_marketingTreasury, msg.sender, block.timestamp);
    }

    function setDevFee(uint _fee) public onlyManager(msg.sender){
        require(_fee > 0, "Ajira Pay: Dev Treasury Fee Cannot be zero or less");
        devTreasuryFeePercent = _fee;
        emit NewDevTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setMarketingFee(uint _fee) public onlyManager(msg.sender){
        require(_fee > 0, "Ajira Pay: Marketing Treasury Fee Cannot be zero or less");
        marketingTreasuryFeePercent = _fee;
        emit NewMarketingTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setLiquidityPoolFeeFactor(uint _newFeeFactor) public onlyManager(msg.sender){
        require(_newFeeFactor > 0,"Ajira Pay: Liquidity Pool Cannot be less than zero");
        liquidityPoolFactor = _newFeeFactor;
        minimumTokensBeforeSwap = totalSupply().div(_newFeeFactor);
        emit NewLiquidityFeeFactor(msg.sender, _newFeeFactor, block.timestamp);
    }

    function activateTaxHoliday() public onlyManager(msg.sender){
        isInTaxHolidayPhase = true;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    function deActivateTaxHoliday() public onlyManager(msg.sender){
        isInTaxHolidayPhase = false;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    receive() external payable{}

    //recover tokens sent to this address by investor wrongfully, upon request 
    function recoverLostTokensForInvestor(address _token, uint _amount) public nonReentrant
    onlyManager(msg.sender)
    {
        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, _amount);
        emit ERC20TokenRecovered(_token, msg.sender, _amount, block.timestamp);
        require(_token != address(this), "Owner cannot claim native tokens");
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
    }

    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

    function decimals() public view returns(uint){
        return _decimals;
    }

    function totalSupply() public view override returns(uint){
        return _totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint){
        return balances[_account];
    }

    function allowance(address _owner, address _spender) public view returns (uint){
        return allowances[_owner][_spender];
    }

    //TODO add fee and dex logic here(_transfer)
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public virtual override returns (bool) {
        address _owner = _msgSender();
        _approve(_owner, _spender, _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, _spender, allowance(owner, _spender) + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, _spender);
        require(currentAllowance >= _subtractedValue, "Ajira Pay: decreased allowance below zero");
        unchecked {
            _approve(owner, _spender, currentAllowance.sub(_subtractedValue));
        }

        return true;
    }

    function recoverEth(uint _amount) public nonReentrant onlyManager(msg.sender) returns(bool){
        uint contractBalance = address(this).balance;
        require(_amount >= contractBalance,"Ajira Pay: Insufficient Withdrawal Balance");
        payable(msg.sender).transfer(_amount);
        emit EthWithdrawal(msg.sender, _amount, block.timestamp);
        return true;
    }

    function setNewRouterAddress(address _router) public 
    nonZeroAddress(_router) 
    onlyManager(msg.sender)
    returns(bool)
    {
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(_router);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        pancakeswapV2Router = _pancakeswapV2Router;
        emit NewRouterAddressSet(msg.sender, _router, block.timestamp);
        return true;
    }

    function setMinTokensToAddLiquidityBeforeSwap(uint _amount) onlyManager(msg.sender) public returns(bool){
        require(_amount != 0,"Ajira Pay: Zero Amount for liquidity not allowed");
        minimumTokensBeforeSwap = _amount;
        emit MinLiquidityAmountUpdated(msg.sender, _amount, block.timestamp);
        return true;
    }

    function excludeFromFee(address _account) public 
    nonZeroAddress(_account) 
    onlyManager(msg.sender)
    returns(bool)
    {
        excludedFromFee[_account] = true;
        emit ExcludeFromFee(msg.sender, _account, block.timestamp);
        return true;
    }

    function includeInFee(address _account) public 
    nonZeroAddress(_account) 
    onlyManager(msg.sender)
    returns(bool){
        excludedFromFee[_account] = false;
        emit IncludeInFee(msg.sender, _account, block.timestamp);
        return true;
    }

    function addToBlackList(address _account) public 
    nonZeroAddress(_account)
    onlyManager(msg.sender) 
    returns(bool)
    {
        isBlacklistedAddress[_account] = true;
        emit NewBlackListAction(msg.sender, _account, block.timestamp);
        return true;
    }

    function removeFromBlackList(address _account) public 
    nonZeroAddress(_account) 
    onlyManager(msg.sender)
    returns(bool){
        isBlacklistedAddress[_account] = false;
        emit AccountRemovedFromBlackList(msg.sender, _account, block.timestamp);
        return true;
    }

    function whiteListMerchant(address _merchant) public 
    nonZeroAddress(_merchant) 
    onlyManager(msg.sender)
    returns(bool)
    {
        require(isWhiteListedMerchant[_merchant] == false,"Ajira Pay: Merchant is Listed");
        isWhiteListedMerchant[_merchant] = true;
        whiteListedMerchants.push(_merchant);
        emit NewMerchantWhiteListed(msg.sender, _merchant, block.timestamp);
        return true;
    }

    function deListMerchant(address _merchant) public 
    nonZeroAddress(_merchant) 
    onlyManager(msg.sender)
    returns(bool)
    {
        require(isWhiteListedMerchant[_merchant] == true,"Ajira Pay: Merchant is DeListed");
        isWhiteListedMerchant[_merchant] = false;
        emit MerchantDelisted(msg.sender, _merchant, block.timestamp);
        return true;
    }

    function transferAndCall(address to, uint256 amount) public override returns (bool){
        //transferAndCall(to, amount, "");
        //return true;
    }

    function transferAndCall(
        address to,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool){
        transfer(to, amount);
        require(_checkAndCallTransfer(_msgSender(), to, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool){
        //return transferFromAndCall(from, to, amount, "");
    }

    function transferFromAndCall(
        address from,
        address to,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool){
        transferFrom(from, to, amount);
        require(_checkAndCallTransfer(from, to, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }
    
    function approveAndCall(address spender, uint256 amount) public override returns (bool){
        //return approveAndCall(spender, amount, "");
    }

    function approveAndCall(
        address spender,
        uint256 amount,
        bytes calldata data
    ) public override returns (bool){
        approve(spender, amount);
        require(_checkAndCallApprove(spender, amount, data), "ERC1363: _checkAndCallApprove reverts");
        return true;
    }
    function onTransferReceived(
        address spender,
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4){

    }

    function onApprovalReceived(
        address sender,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4){

    }
    //Internal Functions 
    function _checkAndCallTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!recipient.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data);
        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);
    }

    function _checkAndCallApprove(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal virtual returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data);
        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), "Ajira Pay: transfer from the zero address");
        require(_to != address(0), "Ajira Pay: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;

        if (overMinTokenBalance && !inSwapAndLiquify && _from != pancakeswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = minimumTokensBeforeSwap;
            _swapAndLiquidify(contractTokenBalance);
        }

        bool takeFee = true;

        if(excludedFromFee[_from] || excludedFromFee[_to]){
            takeFee = false;
        }
        /*
        uint256 fromBalance = balances[_from];
        require(fromBalance >= _amount, "Ajira Pay: transfer amount exceeds balance");
        unchecked {
            balances[_from] = fromBalance.sub(_amount);
        }
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);
        **/
        _afterTokenTransfer(_from, _to, _amount);
    }

    function _approve(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_owner != address(0), "Ajira Pay:: approve from the zero address");
        require(_spender != address(0), "Ajira Pay:: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _mint(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Ajira Pay: mint to the zero address");

        _beforeTokenTransfer(address(0), _account, _amount);

        _totalSupply = _totalSupply.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);

        _afterTokenTransfer(address(0), _account, _amount);
    }

    function _burn(address _account, uint256 _amount) internal virtual {
        require(_account != address(0), "Ajira Pay: burn from the zero address");

        _beforeTokenTransfer(_account, address(0), _amount);

        uint256 accountBalance = balances[_account];
        require(accountBalance >= _amount, "Ajira Pay: burn amount exceeds balance");
        unchecked {
            balances[_account] = accountBalance.sub(_amount);
        }
        _totalSupply = _totalSupply.sub(_amount);

        emit Transfer(_account, address(0), _amount);

        _afterTokenTransfer(_account, address(0), _amount);
    }

    function _spendAllowance(
        address _owner,
        address _spender,
        uint256 _amount
    ) internal virtual {
        uint256 currentAllowance = allowance(_owner, _spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _amount, "Ajira Pay: insufficient allowance");
            unchecked {
                _approve(_owner, _spender, currentAllowance.sub(_amount));
            }
        }
    }

    function _calculateDevTreasuryFee(uint _amount) private view returns(uint){
        return _amount.mul(devTreasuryFeePercent).div(MAX_FEE_FACTOR);
    }

    function _calculateMarketingTreasuryFee(uint _amount) private view returns(uint){
        return _amount.mul(marketingTreasuryFeePercent).div(MAX_FEE_FACTOR);
    }

    function _swapAndLiquidify(uint256 _contractTokenBalance) private {
        uint256 half = _contractTokenBalance.div(2);
        uint256 otherHalf = _contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        _swapTokensForBNB(half);
        
        uint newBalanceAfterSwap = address(this).balance.sub(initialBalance);

        uint devTreasuryFundsFromFee = _calculateDevTreasuryFee(newBalanceAfterSwap);
        uint marketingTreasuryFundsFromFee = _calculateMarketingTreasuryFee(newBalanceAfterSwap);

        _sendFeeToTreasury(devTreasury, devTreasuryFundsFromFee);
        _sendFeeToTreasury(marketingTreasury, marketingTreasuryFundsFromFee);

        uint remainingBnbBalanceAfterFeeDeductions = address(this).balance.sub(devTreasuryFundsFromFee).sub(marketingTreasuryFundsFromFee);

        // add liquidity to pancakeswap
        _addLiquidity(otherHalf, remainingBnbBalanceAfterFeeDeductions);

        emit SwapAndLiquidify(half, remainingBnbBalanceAfterFeeDeductions, otherHalf);
    }

    function _swapTokensForBNB(uint256 _numTokensToSell) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();

        _approve(address(this), address(pancakeswapV2Router), _numTokensToSell);

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _numTokensToSell,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    function _addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), _tokenAmount);

        // add the liquidity
        pancakeswapV2Router.addLiquidityETH{value: _bnbAmount}(
            address(this),
            _tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), //TODO Auto Liquidity should go to an unreachable address (DEAD )
            block.timestamp
        );
    }

    function _sendFeeToTreasury(address payable _treasury, uint _amount) private{
        _treasury.transfer(_amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}