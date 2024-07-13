// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ICrimeDAOToken {
    event TokenMinted(address indexed to, uint256 tokenAmount, uint256 ethAmount);
    event TokensBurned(address indexed from, uint256 tokenAmount, uint256 ethAmount);
    event Withdrawal(address indexed to, uint256 ethAmount);

    function mint(uint256 amountOfTokens) external payable;
    function burn(uint256 amount) external;
    function withdraw(uint256 amount) external;
}
