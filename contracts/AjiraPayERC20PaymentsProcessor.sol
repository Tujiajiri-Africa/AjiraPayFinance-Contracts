// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract AjiraPayERC20PaymentsProcessor is Ownable, AccessControl,ReentrancyGuard{
    using SafeERC20 for IERC20;

    bytes32 constant PAYMENT_MANAGER_ROLE = keccak256("PAYMENT_MANAGER_ROLE");

    event SendDirectERC20Payment(address indexed tokenAddress, address indexed payer, address indexed payee, uint amount, uint timestamp);
    event ScheduleSecurePayment(address indexed tokenAddress, address indexed payer, address indexed payee, uint amount, uint timestamp);
    event CancelPayment();
    event EmergencyCancelPayment();
    event EmergencySendPayment();
    event SecurelyPayWithAjiraPay(address indexed tokenAddress, address indexed payer, address indexed payee, uint amount, uint timestamp);

    enum PaymentStatus { SUCCESS, FAILED, PENDING, CANCELLED }

    constructor(){}

    struct PaymentRequest{
        address tokenAddress;
        address payable merchant;
        address payable client;
        uint releaseDate;
        uint256 amount;
        string currency;
        string desiredCurrency;
        uint dateOfRequest;
        uint fee;
        bool takeFee;
    }

    function sendDirectERC20PaymentWithZeroFee(
        address tokenAddress,
        address payable payer,
        address payable payee,
        uint256 amount,
        uint256 paymentFee,
        uint256 releaseDate
    ) public nonReentrant{
        require(tokenAddress != address(0),"Invalid Address");
        require(payer != address(0),"Invalid Sender");
        require(payee != address(0),"Invalid Recepient");
        require(amount != 0,"Amount Cannot be zero");
        emit SendDirectERC20Payment(tokenAddress,payer,payee,amount, block.timestamp);
        IERC20(tokenAddress).safeTransferFrom(payer, payee, amount);
        
    }

}