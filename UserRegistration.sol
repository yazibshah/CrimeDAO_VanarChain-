// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/IUserRegistration.sol";
import "hardhat/console.sol";
contract UserRegistration is Ownable , IUserRegistration{
    using Counters for Counters.Counter;
    Counters.Counter private _userIdCounter;


    

    mapping(address => User) private users;

    

    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    uint256 private constant TOKEN_UNIT = 10 ** 18;
    address public immutable crimeDAOTokenAddress;
    address mainOwner=tx.origin;
    IERC20 private crimeDAOToken;

    constructor(address _crimeDAOTokenAddress) Ownable(msg.sender) {
        crimeDAOTokenAddress = _crimeDAOTokenAddress;
        crimeDAOToken = IERC20(_crimeDAOTokenAddress);
    }

    function registerUser(string memory name, string memory email) external payable {
        require(!users[msg.sender].registered, "User already registered");
        require(msg.value >= REGISTRATION_FEE, "Insufficient ETH for registration");
        uint256 returnedFee=msg.value-REGISTRATION_FEE;
        console.log(returnedFee);
        
        if(returnedFee>0){
        (bool extraFee, ) = payable(msg.sender).call{value: returnedFee}("");
        require(extraFee,"Refund Fail");
        console.log(extraFee);

        }

        _userIdCounter.increment();
        uint256 newUserId = _userIdCounter.current();


        // Forward ETH to the CrimeDAOToken contract's receive function
        (bool success, ) = payable(crimeDAOTokenAddress).call{value: REGISTRATION_FEE}("");
        require(success, "Failed to send ETH to CrimeDAOToken contract");
        users[msg.sender] = User(newUserId, msg.sender, name, email, true);
        emit UserRegistered(newUserId, msg.sender, name, email);
    }

    function getUser(address userAddress) external view returns (User memory) {
        require(users[userAddress].registered, "User not registered");
        return users[userAddress];
    }

    function balanceOf() external view onlyOwner returns (uint256){
         return crimeDAOToken.balanceOf(address(this));
    }

    function transfer(address recipient, uint256 amount) external onlyOwner returns (bool){
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        uint _amount=amount*TOKEN_UNIT;
        bool success = crimeDAOToken.transfer(recipient,_amount);
        require(success, "Token transfer failed");
        
        return success;
    }

    // Fallback function to receive ETH
    receive() external payable {
        require(msg.value>0,"Insufficient Fund");
        (bool EthTranOwner,)=payable(owner()).call{value:msg.value}("");
        require(EthTranOwner,"Transaction Fail");
        emit EthReceived(msg.sender, msg.value);
    }
}
