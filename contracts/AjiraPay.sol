// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

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

contract AjiraPay is Ownable,AccessControl,ReentrancyGuard, IERC20{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    address public devTreasury;
    address public marketingTreasury;

    uint public devTreasuryFee;
    uint public marketingTreasuryFee;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;
    mapping(address => bool) public excludedFromFee;

    bool isInTaxHolidayPhase = false;

    IPancakeRouter02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public minimumTokensBeforeSwap = 2 * 10**6 * 10**_decimals;

    modifier nonZeroAddress(address _account){
        require(_account != address(0), "Ajira Pay: Zero Address detected");
        _;
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event NewDevTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event NewMarketingTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event NewDevTreasuryFee(address indexed caller, uint indexed newDevTreasuryFee, uint timestamp);
    event NewMarketingTreasuryFee(address indexed caller, uint indexed newMarketingTresuryFee, uint indexed timestamp);
    event EthWithdrawal(address indexed caller, uint indexed amount, uint indexed timestamp);
    event NewRouterAddressSet(address indexed caller, address indexed newAddress, uint indexed timestamp);
    event EcludeFromFee(address indexed caller, address indexed account, uint timestamp);
    event IncludeInFee(address indexed caller, address indexed account, uint timestamp);

    constructor(address _router){
        require(_router != address(0),"Ajira Pay: Zero Address detected");

        _setupRole(MANAGER_ROLE, _msgSender());

        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(_router);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        pancakeswapV2Router = _pancakeswapV2Router;

        _name = 'Ajira Pay';
        _symbol = 'AJP';
        _decimals = 18;
        _totalSupply = 200_000_000 * 10 ** _decimals;
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setDevTreasury(address payable _devTreasury) public nonZeroAddress(_devTreasury){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        devTreasury = _devTreasury;
        emit NewDevTreasury(_devTreasury, msg.sender, block.timestamp);
    }

    function setMarketingTreasury(address payable _marketingTreasury) public nonZeroAddress(_marketingTreasury){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        marketingTreasury = _marketingTreasury;
        emit NewMarketingTreasury(_marketingTreasury, msg.sender, block.timestamp);
    }

    function setDevFee(uint _fee) public{
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        require(_fee > 0, "Ajira Pay: Dev Treasury Fee Cannot be zero or less");
        devTreasuryFee = _fee;
        emit NewDevTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setMarketingFee(uint _fee) public{
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        require(_fee > 0, "Ajira Pay: Marketing Treasury Fee Cannot be zero or less");
        marketingTreasuryFee= _fee;
        emit NewMarketingTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function activateTaxHoliday() public{
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        isInTaxHolidayPhase = true;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    receive() external payable{}

    //recover tokens sent to this address by investor wrongfully, upon request 
    function recoverLostTokensForInvestor(address _token, uint _amount) public nonReentrant{
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        IERC20 token = IERC20(_token);
        token.safeTransfer(msg.sender, _amount);
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

    //TODO add fee and dex logic here
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, _to, _amount);
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

    function recoverEth(uint _amount) public nonReentrant returns(bool){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        uint contractBalance = address(this).balance;
        require(_amount >= contractBalance,"Ajira Pay: Insufficient Withdrawal Balance");
        payable(msg.sender).transfer(_amount);
        emit EthWithdrawal(msg.sender, _amount, block.timestamp);
        return true;
    }

    function setNewRouterAddress(address _router) public nonZeroAddress(_router) returns(bool){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        IPancakeRouter02 _pancakeswapV2Router = IPancakeRouter02(_router);
        pancakeswapV2Pair = IPancakeswapV2Factory(_pancakeswapV2Router.factory())
            .createPair(address(this), _pancakeswapV2Router.WETH());

        pancakeswapV2Router = _pancakeswapV2Router;
        emit NewRouterAddressSet(msg.sender, _router, block.timestamp);
        return true;
    }

    function excludeFromFee(address _account) public nonZeroAddress(_account) returns(bool){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        excludedFromFee[_account] = true;
        emit EcludeFromFee(msg.sender, _account, block.timestamp);
        return true;
    }

    function includeInFee(address _account) public nonZeroAddress(_account) returns(bool){
        require(hasRole(MANAGER_ROLE, msg.sender),"Ajira Pay: An unathorized account");
        excludedFromFee[_account] = false;
        emit IncludeInFee(msg.sender, _account, block.timestamp);
        return true;
    }

    //Internal Functions 
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {
        require(_from != address(0), "Ajira Pay: transfer from the zero address");
        require(_to != address(0), "Ajira Pay: transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _amount);

        uint256 fromBalance = balances[_from];
        require(fromBalance >= _amount, "Ajira Pay: transfer amount exceeds balance");
        unchecked {
            balances[_from] = fromBalance.sub(_amount);
        }
        balances[_to] = balances[_to].add(_amount);

        emit Transfer(_from, _to, _amount);

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