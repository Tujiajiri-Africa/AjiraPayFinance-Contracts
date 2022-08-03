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


contract AjiraPay is Ownable,AccessControl,ReentrancyGuard, IERC20{
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    uint private _decimals;
    uint private _totalSupply;

    address public devTreasury;
    address public marketingTreasury;

    uint public devTreasuryFee;
    uint public marketingTreasuryFee;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    modifier nonZeroAddress(address _account){
        require(_account != address(0), "Ajira Pay: Zero Address detected");
        _;
    }

    event NewDevTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event NewMarketingTreasury(address indexed account, address indexed caller, uint indexed timestamp);
    event TaxHolidayActivated(address indexed caller, uint indexed timestamp);
    event NewDevTreasuryFee(address indexed caller, uint indexed newDevTreasuryFee, uint timestamp);
    event NewMarketingTreasuryFee(address indexed caller, uint indexed newMarketingTresuryFee, uint indexed timestamp);

    constructor(address _router){
        require(_router != address(0),"Ajira Pay: Zero Address detected");

        _name = 'Ajira Pay';
        _symbol = 'AJP';
        _decimals = 18;
        _totalSupply = 200_000_000 * 10 ** _decimals;
        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setDevTreasury(address payable _devTreasury) public nonZeroAddress(_devTreasury) onlyOwner{
        devTreasury = _devTreasury;
        emit NewDevTreasury(_devTreasury, msg.sender, block.timestamp);
    }

    function setMarketingTreasury(address payable _marketingTreasury) public nonZeroAddress(_marketingTreasury) onlyOwner{
        marketingTreasury = _marketingTreasury;
        emit NewMarketingTreasury(_marketingTreasury, msg.sender, block.timestamp);
    }

    function setDevFee(uint _fee) public onlyOwner{
        require(_fee > 0, "Ajira Pay: Dev Treasury Fee Cannot be zero or less");
        devTreasuryFee = _fee;
        emit NewDevTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function setMarketingFee(uint _fee) public onlyOwner{
        require(_fee > 0, "Ajira Pay: Marketing Treasury Fee Cannot be zero or less");
        marketingTreasuryFee= _fee;
        emit NewMarketingTreasuryFee(msg.sender, _fee, block.timestamp);
    }

    function activateTaxHoliday() public onlyOwner{
        devTreasuryFee = 0;
        marketingTreasuryFee = 0;
        emit TaxHolidayActivated(msg.sender, block.timestamp);
    }

    receive() external payable{}

    //recover tokens sent to this address by investor wrongfully, upon request 
    function recoverLostTokensForInvestor(address _token, uint _amount) public onlyOwner{
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

    //Internal Functions 
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "Ajira Pay: transfer from the zero address");
        require(to != address(0), "Ajira Pay: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = balances[from];
        require(fromBalance >= amount, "Ajira Pay: transfer amount exceeds balance");
        unchecked {
            balances[from] = fromBalance.sub(amount);
        }
        balances[to] = balances[to].add(amount);

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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