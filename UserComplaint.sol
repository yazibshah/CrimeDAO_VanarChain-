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

    constructor(address userRegistrationAddress, address tokenAddress) Ownable(msg.sender) {
        userRegistration = UserRegistration(payable(userRegistrationAddress));
        crimeDAOToken = CrimeDAOToken(payable(tokenAddress));
    }

    function fileComplaint(string memory description, string[] memory _uri) external payable override onlyRegisteredUser {
        require(userRegistration.getUser(msg.sender).registered, "Please register yourself");
        require(msg.value >= COMPLAINT_FEE, "Incorrect complaint fee");

        uint256 returnedFee = msg.value - COMPLAINT_FEE;
        if (returnedFee > 0) {
            (bool extraFee, ) = payable(msg.sender).call{value: returnedFee}("");
            require(extraFee, "Refund failed");
        }

        (bool success, ) = payable(crimeDAOToken).call{value: COMPLAINT_FEE}("");
        require(success, "Failed to send ETH to CrimeDAOToken contract");

        _complaintIdCounter.increment();
        uint256 newComplaintId = _complaintIdCounter.current();

        complaints[newComplaintId] = Complaint(newComplaintId, msg.sender, description, msg.value, _uri, false);

        emit ComplaintFiled(newComplaintId, msg.sender, description, msg.value, _uri);
    }

    function uploadFiles(string[] memory _uri, uint256 _complaintId) external {
    require(msg.sender == complaints[_complaintId].userAddress, "You are not the complaint owner");
    Complaint storage complaint = complaints[_complaintId];
    uint256 length = _uri.length;
    for (uint256 i = 0; i < length; i++) {
        complaint.uri.push(_uri[i]);
    }
}

    function deleteFile(uint256 complaintId, string memory _uri) external override {
        require(complaints[complaintId].userAddress == msg.sender, "Not authorized");

        Complaint storage complaint = complaints[complaintId];

        bool found = false;
        for (uint256 i = 0; i < complaint.uri.length; i++) {
            if (keccak256(abi.encodePacked(complaint.uri[i])) == keccak256(abi.encodePacked(_uri))) {
                found = true;
                // Remove the ipfsHash by replacing it with the last element and then popping the array
                delete complaint.uri[i];
                emit FileDeleted(complaintId, _uri);
                break;
            }
        }

        require(found, "IPFS hash not found in complaint");
    }

        

    function getComplaint(uint256 complaintId) external view override returns (Complaint memory) {
        require(complaints[complaintId].userAddress == msg.sender || owner() == msg.sender, "Not authorized");
        return complaints[complaintId];
    }


    function balanceOf() external view override onlyOwner returns (uint256) {
        return crimeDAOToken.balanceOf(address(this));
    }

    function transfer(address recipient, uint256 amount) external override onlyOwner returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than zero");
        uint256 _amount = amount * TOKEN_UNIT;
        bool success = crimeDAOToken.transfer(recipient, _amount);
        require(success, "Token transfer failed");
        return success;
    }

    modifier onlyRegisteredUser() {
        require(userRegistration.getUser(msg.sender).registered, "User not registered");
        _;
    }

    receive() external payable {
        require(msg.value > 0, "Insufficient fund");
        (bool ethTranOwner, ) = payable(owner()).call{value: msg.value}("");
        require(ethTranOwner, "Transaction failed");
        emit EthReceived(msg.sender, msg.value);
    }
}
