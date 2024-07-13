// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interface/IRegisterInvestigator.sol";
import "./CrimeDAOToken.sol";

contract RegisterInvestigater is Ownable, IRegisterInvestigater {
    using Counters for Counters.Counter;
    Counters.Counter private _investigatorIdCounter;

    

    mapping(address => Investigator) private investigators;
    CrimeDAOToken public immutable  crimeDAOToken;
    uint256 public constant REGISTRATION_FEE = 0.5 ether;
    uint256 private constant TOKEN_UNIT = 10 ** 18;
    

    

    constructor(address tokenAddress) Ownable(msg.sender){
        crimeDAOToken = CrimeDAOToken(payable (tokenAddress));
        
    }

    function registerInvestigator(string memory name, string memory email ,string memory qualifications) external payable {
        require(!investigators[msg.sender].registered, "Investigator already registered");
        require(msg.value >= REGISTRATION_FEE, "Incorrect registration fee");

        _investigatorIdCounter.increment();
        uint256 newInvestigatorId = _investigatorIdCounter.current();
        uint256 returnedFee=msg.value-REGISTRATION_FEE;
        console.log(returnedFee);
        
        if(returnedFee>0){
        (bool extraFee, ) = payable(msg.sender).call{value: returnedFee}("");
        require(extraFee,"Refund Fail");
        console.log(extraFee);

        }

        
        (bool success, ) = payable(crimeDAOToken).call{value: REGISTRATION_FEE}("");
        require(success, "Failed to send ETH to CrimeDAOToken contract");
        investigators[msg.sender] = Investigator(newInvestigatorId, msg.sender, name, email , qualifications, true);

        emit InvestigatorRegistered(newInvestigatorId, msg.sender, name, qualifications);
    }

    function getInvestigator(address investigatorAddress) external view returns (Investigator memory) {
        require(investigators[investigatorAddress].registered, "Investigator not registered");
        return investigators[investigatorAddress];
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

    receive() external payable {
        require(msg.value>0,"Insufficient Fund");
        (bool EthTranOwner,)=payable(owner()).call{value:msg.value}("");
        require(EthTranOwner,"Transaction Fail");
        emit EthReceived(msg.sender, msg.value);
     }
}
