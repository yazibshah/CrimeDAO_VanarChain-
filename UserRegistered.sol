// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";
contract UserRegistration is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _userIdCounter;

    struct User {
        uint256 id;
        address userAddress;
        string name;
        string email;
        bool registered;
    }

    mapping(address => User) private users;

    event UserRegistered(uint256 userId, address userAddress, string name, string email);
    event EthReceived(address from, uint256 amount);

    uint256 public constant REGISTRATION_FEE = 0.01 ether;
    address public immutable crimeDAOTokenAddress;

    constructor(address _crimeDAOTokenAddress) Ownable(msg.sender) {
        crimeDAOTokenAddress = _crimeDAOTokenAddress;
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

        users[msg.sender] = User(newUserId, msg.sender, name, email, true);

        // Forward ETH to the CrimeDAOToken contract's receive function
        (bool success, ) = payable(crimeDAOTokenAddress).call{value: REGISTRATION_FEE}("");
        require(success, "Failed to send ETH to CrimeDAOToken contract");

        emit UserRegistered(newUserId, msg.sender, name, email);
    }

    function getUser(address userAddress) external view returns (User memory) {
        require(users[userAddress].registered, "User not registered");
        return users[userAddress];
    }

    // Fallback function to receive ETH
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }
}
