// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interface/ICrimeDAOToken.sol";
import "hardhat/console.sol";
contract CrimeDAOToken is ERC20, Ownable , ICrimeDAOToken{
    uint256 public constant TOKEN_DECIMALS = 18;
    uint256 public constant TOKEN_PRICE_WEI = 0.01 ether;
    uint256 private constant TOKEN_UNIT = 10 ** TOKEN_DECIMALS; // ** Optimized: Precompute this once **

    error InsufficientEth();
    error InsufficientTokenBalance();
    error ContractBalanceInsufficient();
    error InsufficientEthProvided();
    error ContractDoesNotAcceptEth();

    constructor() ERC20("CrimeDAOToken", "CRDAO") Ownable(msg.sender) {
        _mint(msg.sender, 100 * TOKEN_UNIT); // ** Optimized: Use precomputed value **
    }

    // =============Mint Function====================
    function mint(uint256 amountOfTokens) external payable {
    require(amountOfTokens > 0, "Token amount must be greater than zero");

    uint256 requiredEth = ((amountOfTokens*TOKEN_UNIT) * TOKEN_PRICE_WEI) / TOKEN_UNIT;
    console.log(requiredEth);

    // Ensure at least the minimum ETH is provided based on TOKEN_PRICE_WEI
    require(msg.value >= requiredEth && msg.value > 0, "Insufficient ETH provided");

    _mint(msg.sender, amountOfTokens * TOKEN_UNIT);
    emit TokenMinted(msg.sender, amountOfTokens, msg.value);

    // Refund any excess ETH sent
    if (msg.value > requiredEth) {
        (bool success, ) = msg.sender.call{value: msg.value - requiredEth}("");
        require(success, "Refund failed");
    }
}

    //=============Burnable Function====================
    function burn(uint256 amount) external {
        if (balanceOf(msg.sender) < amount * TOKEN_UNIT) {
            revert InsufficientTokenBalance(); // ** Optimized: Use custom error **
        }

        uint256 ethToReturn = ((amount*TOKEN_UNIT) * TOKEN_PRICE_WEI * (75*TOKEN_UNIT)) / (100 * TOKEN_UNIT); // ** Optimized: Combine calculations **
        console.log(ethToReturn/1 ether);

        require(address(this).balance >= ethToReturn/1 ether,"Contract Does have not enoungh balance");
        _burn(msg.sender, amount * TOKEN_UNIT); // ** Optimized: Use precomputed value **

        (bool success, ) = msg.sender.call{value: ethToReturn/1 ether}(""); // ** Optimized: Use call instead of transfer **
        require(success, "ETH transfer failed");

        emit TokensBurned(msg.sender, amount, ethToReturn);
    }

    // Receive function to accept ETH and mint tokens
    receive() external payable {
        uint256 tokenCal = (msg.value * TOKEN_UNIT) / TOKEN_PRICE_WEI;

        if (tokenCal == 0) {
            revert InsufficientEthProvided(); // ** Optimized: Use custom error **
        }

        _mint(msg.sender, tokenCal);
        emit TokenMinted(msg.sender, tokenCal, msg.value);
    }

    // Withdraw ETH from the contract (onlyOwner)
    function withdraw(uint256 amount) external onlyOwner {
        console.log(amount);//error
        if (address(this).balance < amount) {
            revert ContractBalanceInsufficient(); // ** Optimized: Use custom error **
        }
        (bool success, ) = payable(owner()).call{value: amount}(""); // ** Optimized: Use call instead of transfer **
        require(success, "Withdrawal failed");
        emit Withdrawal(owner(), amount);
    }

    // Fallback function to reject ETH transfers
    fallback() external payable {
        revert ContractDoesNotAcceptEth(); // ** Optimized: Use custom error **
    }
}
