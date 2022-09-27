// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
//import 'erc-payable-token/contracts/token/ERC1363/ERC1363.sol';
import 'erc-payable-token/contracts/token/ERC1363/IERC1363.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import "./interfaces/IPancakeRouter02.sol";
import "./interfaces/IPancakeswapV2Factory.sol";
import "./interfaces/IERC1363Spender.sol";
import "./interfaces/IERC1363Receiver.sol";
import './AjiraPayWhiteList.sol';

contract AjiraPay is ERC165,IERC1363,AjiraPayWhiteList{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowances;

    mapping(address => bool) public excludedFromFee;

    address private pancakeswapTestnetRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address private pancakeswapMainnetRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;

    IPancakeRouter02 public pancakeswapV2Router;
    address public pancakeswapV2Pair;

    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public minimumTokensBeforeSwap;
    uint256 public maxTxAmount;

    uint public constant MAX_FEE_FACTOR = 100;
    uint public liquidityPoolFactor;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyManager(address _account){
        require(hasRole(MANAGER_ROLE, _account),"Ajira Pay: An unauthorized account");
        _;
    }
    
    event NewRouterAddressSet(address indexed caller, address indexed newAddress, uint indexed timestamp);
    event ExcludeFromFee(address indexed caller, address indexed account, uint timestamp);
    event IncludeInFee(address indexed caller, address indexed account, uint timestamp);
    event MinLiquidityAmountUpdated(address indexed caller, uint newAmount, uint indexed timestamp);
    event SwapAndLiquidify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event NewLiquidityFeeFactor(address caller, uint newFeeFactor, uint timestamp);

    constructor(address _router){
        require(_router != address(0),"Ajira Pay: Zero Address detected");

        _grantRole(MANAGER_ROLE, _msgSender());

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
        
        liquidityPoolFactor = 1000;
        minimumTokensBeforeSwap = _totalSupply.div(liquidityPoolFactor);
        //maxTxAmount = 5000_000 * 10** _decimals;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl,ERC165, IERC165) returns (bool) {
        return 
            interfaceId == type(IERC1363).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setLiquidityPoolFeeFactor(uint _newFeeFactor) public onlyManager(msg.sender){
        require(_newFeeFactor > 0,"Ajira Pay: Liquidity Pool Cannot be less than zero");
        liquidityPoolFactor = _newFeeFactor;
        minimumTokensBeforeSwap = totalSupply().div(_newFeeFactor);
        emit NewLiquidityFeeFactor(msg.sender, _newFeeFactor, block.timestamp);
    }

    receive() external payable{}
 
    function name() public view returns(string memory){return _name;}

    function symbol() public view returns(string memory){return _symbol;}

    function decimals() public view returns(uint){return _decimals;}

    function totalSupply() public view override returns(uint){return _totalSupply;}

    function balanceOf(address _account) public view override returns (uint){return balances[_account];}

    function allowance(address _owner, address _spender) public view returns (uint){return allowances[_owner][_spender];}

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool) {
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

    function setNewRouterAddress(address _router) public nonZeroAddress(_router) onlyManager(msg.sender)returns(bool){
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

    function excludeFromFee(address _account) public nonZeroAddress(_account) onlyManager(msg.sender)returns(bool){
        excludedFromFee[_account] = true;
        emit ExcludeFromFee(msg.sender, _account, block.timestamp);
        return true;
    }

    function includeInFee(address _account) public nonZeroAddress(_account) onlyManager(msg.sender)returns(bool){
        excludedFromFee[_account] = false;
        emit IncludeInFee(msg.sender, _account, block.timestamp);
        return true;
    }

    function transferAndCall(address to, uint256 amount) public override returns (bool){
        //transferAndCall(to, amount, "");
        //return true;
    }

    function transferAndCall(address to,uint256 amount,bytes calldata data) public override returns (bool){
        transfer(to, amount);
        require(_checkAndCallTransfer(_msgSender(), to, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }

    function transferFromAndCall(address from,address to,uint256 amount) public override returns (bool){
        //return transferFromAndCall(from, to, amount, "");
    }

    function transferFromAndCall(address from,address to,uint256 amount,bytes calldata data) public override returns (bool){
        transferFrom(from, to, amount);
        require(_checkAndCallTransfer(from, to, amount, data), "ERC1363: _checkAndCallTransfer reverts");
        return true;
    }
    
    function approveAndCall(address spender, uint256 amount) public override returns (bool){
        //return approveAndCall(spender, amount, "");
    }

    function approveAndCall(address spender,uint256 amount,bytes calldata data) public override returns (bool){
        approve(spender, amount);
        require(_checkAndCallApprove(spender, amount, data), "ERC1363: _checkAndCallApprove reverts");
        return true;
    }

    function onTransferReceived(address spender,address sender,uint256 amount,bytes calldata data) external returns (bytes4){}

    function onApprovalReceived(address sender,uint256 amount,bytes calldata data) external returns (bytes4){}

    function _checkAndCallTransfer(address sender,address recipient,uint256 amount,bytes memory data) internal virtual returns (bool) {
        if (!recipient.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(_msgSender(), sender, amount, data);
        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);
    }

    function _checkAndCallApprove(address spender,uint256 amount,bytes memory data) internal virtual returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(_msgSender(), amount, data);
        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);
    }

    function _transfer(address _from,address _to,uint256 _amount) internal virtual {
        require(_from != address(0), "Ajira Pay: transfer from the zero address");
        require(_to != address(0), "Ajira Pay: transfer to the zero address");

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
        _performTokenTransfer(_from, _to, _amount, takeFee);
    }

    function _approve(address _owner,address _spender,uint256 _amount) internal virtual {
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

    function _spendAllowance(address _owner,address _spender,uint256 _amount) internal virtual {
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
            DEAD, //owner(), //TODO Auto Liquidity should go to an unreachable address (DEAD )
            block.timestamp
        );
    }

    function _sendFeeToTreasury(address payable _treasury, uint _amount) private{
        _treasury.transfer(_amount);
    }

    function _performTokenTransfer(address _from, address _to, uint _amount, bool _takeFee) private {
        if(!_takeFee) _removeAllFee();

        if(excludedFromFee[_from] && excludedFromFee[_to]){
            _transferBothExcluded(_from, _to, _amount);
        }
        else if(excludedFromFee[_from] && !excludedFromFee[_to]){
            _transferFromExcluded(_from, _to, _amount);
        }
        else if(!excludedFromFee[_from] && excludedFromFee[_to]){
            _transferToExcluded(_from, _to, _amount);
        }
        else{
            _transferStandard(_from, _to, _amount);
        }
        if(!_takeFee) _removeAllFee();
    }

    function _transferFromExcluded(address _from, address _to, uint _amount) private returns(bool){}

    function _transferBothExcluded(address _from, address _to, uint _amount) private returns(bool){}

    function _transferToExcluded(address _from, address _to, uint _amount) private returns(bool){}

    function _transferStandard(address _from, address _to, uint _amount) private returns(bool){
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function _removeAllFee() private{}
    
    function _beforeTokenTransfer(address from,address to,uint256 amount) internal virtual {}

    function _afterTokenTransfer(address from,address to,uint256 amount) internal virtual {}
}