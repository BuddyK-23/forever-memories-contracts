// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ForeverMemoryCollection.sol";

contract ForeverMemoryCollectionFactory {
    address[] public deployedCollections;
    address public owner;

    event CollectionCreated(address collectionAddress, address owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCollection(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        uint256 lsp4TokenType_,
        bytes memory lsp4MetadataURI_,
        uint256 rewardAmount_
    ) external onlyOwner returns (address) {
        ForeverMemoryCollection newCollection = new ForeverMemoryCollection(
            name_,
            symbol_,
            newOwner_,
            lsp4TokenType_,
            lsp4MetadataURI_,
            rewardAmount_
        );
        deployedCollections.push(address(newCollection));
        emit CollectionCreated(address(newCollection), newOwner_);
        return address(newCollection);
    }

    function getDeployedCollections() external view returns (address[] memory) {
        return deployedCollections;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }
}
