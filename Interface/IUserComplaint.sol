// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserComplaint {
    struct Complaint {
        uint256 id;
        address userAddress;
        string description;
        uint256 amount;
        bytes32[] ipfsHashes;
        bool resolved;
    }

    event ComplaintFiled(uint256 complaintId, address userAddress, string description, uint256 amount, bytes32[] ipfsHashes);
    event EthReceived(address from, uint256 amount);

    function fileComplaint(string memory description, bytes32[] memory ipfsHashes) external payable;
    function getComplaint(uint256 complaintId) external view returns (Complaint memory);
    function decodeIpfsHash(bytes32 ipfsHash) external pure returns (string memory);
     function balanceOf() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
