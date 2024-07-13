// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserRegistration {
    struct User {
        uint256 id;
        address userAddress;
        string name;
        string email;
        bool registered;
    }

    event UserRegistered(uint256 userId, address userAddress, string name, string email);
    event EthReceived(address from, uint256 amount);

    function registerUser(string memory name, string memory email) external payable;
    function getUser(address userAddress) external view returns (User memory);
    function balanceOf() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
