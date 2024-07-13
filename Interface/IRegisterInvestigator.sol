// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRegisterInvestigator {
    struct Investigator {
        uint256 id;
        address investigatorAddress;
        string name;
        string email;
        string qualifications;
        bool registered;
    }

    event InvestigatorRegistered(uint256 investigatorId, address investigatorAddress, string name, string qualifications);
    event EthReceived(address from, uint256 amount);

    function registerInvestigator(string memory name, string memory email, string memory qualifications) external payable;
    function getInvestigator(address investigatorAddress) external view returns (Investigator memory);
    function balanceOf() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}
