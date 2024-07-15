// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./UserRegistration.sol";
import "./CrimeDAOToken.sol";
import "./Interface/IUserComplaint.sol";

contract UserComplaint is Ownable, IUserComplaint {
    using Counters for Counters.Counter;
    Counters.Counter private _complaintIdCounter;

    mapping(uint256 => Complaint) private complaints;

    UserRegistration private immutable userRegistration;
    CrimeDAOToken private immutable crimeDAOToken;

    uint256 public constant COMPLAINT_FEE = 0.01 ether;
    uint256 private constant TOKEN_UNIT = 10 ** 18;

    constructor(address userRegistrationAddress, address tokenAddress) Ownable(msg.sender){
        userRegistration = UserRegistration(payable(userRegistrationAddress));
        crimeDAOToken = CrimeDAOToken(payable(tokenAddress));
    }

    function fileComplaint(string memory description, bytes32[] memory ipfsHashes) external payable override onlyRegisteredUser  {
        require(userRegistration.getUser(msg.sender).registered,"please registred your self");
        require(msg.value >= COMPLAINT_FEE, "Incorrect complaint fee");
        uint256 returnedFee=msg.value-COMPLAINT_FEE;
        console.log(returnedFee);
        
        if(returnedFee>0){
        (bool extraFee, ) = payable(msg.sender).call{value: returnedFee}("");
        require(extraFee,"Refund Fail");
        console.log(extraFee);

        }

        
        (bool success, ) = payable(crimeDAOToken).call{value: COMPLAINT_FEE}("");
        require(success, "Failed to send ETH to CrimeDAOToken contract");

        _complaintIdCounter.increment();
        uint256 newComplaintId = _complaintIdCounter.current();

        complaints[newComplaintId] = Complaint(newComplaintId, msg.sender, description, msg.value, ipfsHashes, false);

        // Mint and transfer CrimeDAO tokens
        

        emit ComplaintFiled(newComplaintId, msg.sender, description, msg.value, ipfsHashes);
    }

    function getComplaint(uint256 complaintId) external view override returns (Complaint memory) {
        require(complaints[complaintId].userAddress == msg.sender || owner() == msg.sender,"Not authorized");
        return complaints[complaintId];
    }

    function decodeIpfsHash(bytes32 ipfsHash) external pure  returns (string memory) {
        bytes memory alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
        bytes memory encoded = new bytes(46);
        encoded[0] = alphabet[18];
        encoded[1] = alphabet[27];
        for (uint256 i = 0; i < 32; i++) {
            encoded[i + 2] = alphabet[uint8(ipfsHash[i])];
        }
        return string(encoded);
    }

    modifier onlyRegisteredUser() {
        require(userRegistration.getUser(msg.sender).registered, "User not registered");
        _;
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
