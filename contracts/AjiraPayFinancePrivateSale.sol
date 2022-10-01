// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract AjiraPayFinancePrivateSale is Ownable, AccessControl, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bytes32 constant public MANAGER_ROLE = keccak256('MANAGER_ROLE');

    IERC20 public ajiraPayToken;

    address payable public treasury;

    bool public isPresaleOpen = false;
    bool public isPresalePaused = false;

    uint public totalBNBraised;
    uint public minTokensToPurchasePerWallet;
    uint public maxTokensToPurchasePerWallet;

    mapping(address => uint) public totalTokenContributionsByUser;
    mapping(address => uint) public totalTokenContributionsClaimedByUser;
    mapping(address => uint) public totalUnclaimedTokenContributionsByUser;

    //if 1 token = 0.05
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

    constructor(address _token){
        require(_token != address(0),"Invalid Address");
        _grantRole(MANAGER_ROLE, _msgSender());
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        ajiraPayToken = IERC20(_token); 
        treasury = payable(_msgSender());
    }

    function updateTreasury(address _newTreasury) public onlyRole(MANAGER_ROLE) nonZeroAddress(_newTreasury) presalePaused{

    }

    function contribute() public payable nonReentrant{

    }

    function claimContribution() public nonReentrant{

    }

    receive() external payable{
        contribute();
    }

    function startPresale() public onlyRole(MANAGER_ROLE) presaleClosed{

    }

    function closePresale() public onlyRole(MANAGER_ROLE) presaleOpen{

    }

    function pausePresale() public onlyRole(MANAGER_ROLE) presaleUnpaused{

    }

    function unpausePresale() public onlyRole(MANAGER_ROLE) presalePaused{

    }

    function recoverBNB() public onlyRole(MANAGER_ROLE) nonReentrant{
        treasury.transfer(address(this).balance);
    }

    function recoverLostTokensForInvestor(address _account, uint _amount) public nonReentrant{

    }
}