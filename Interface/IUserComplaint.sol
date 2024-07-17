// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUserComplaint {
    struct Complaint {
        uint256 id;
        address userAddress;
        string description;
        uint256 amount;
        string[] uri;
        bool resolved;
    }

    event ComplaintFiled(uint256 complaintId, address userAddress, string description, uint256 amount, string[] ipfsHashes);
    event EthReceived(address from, uint256 amount);

    function fileComplaint(string memory description, string[] memory _uri) external payable;
    function uploadFiles(string[] memory _uri,uint256 _ComplaintId ) external;
    function getComplaint(uint256 complaintId) external view returns (Complaint memory);
    function balanceOf() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
