// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP7SubCollection} from './LSP7SubCollection.sol';

library LSP8CollectionMinter {
    function mint(
        string memory nameOfLSP7_,
        string memory symbolOfLSP7_,
        uint256 lsp4TokenType_,
        bool isNonDivisible_,
        uint256 totalSupplyOfLSP7_,
        address receiverOfInitialTokens_,
        bytes memory lsp4MetadataURIOfLSP7_
    ) public returns (address lsp7SubCollectionAddress) {
        // Deploy the LSP7SubCollection and set the address as tokenId
        LSP7SubCollection lsp7SubCollection = new LSP7SubCollection(
            nameOfLSP7_,
            symbolOfLSP7_,
            address(this), // Owner of the LSP7SubCollection is this contract (LSP8Minter contract)
            receiverOfInitialTokens_,
            lsp4TokenType_,
            isNonDivisible_,
            totalSupplyOfLSP7_,
            lsp4MetadataURIOfLSP7_
        );

        lsp7SubCollectionAddress = address(lsp7SubCollection);

        // Convert the address of the LSP7SubCollection to bytes32 to use it as tokenId
        // bytes32 tokenId = bytes32(uint256(uint160(lsp7SubCollectionAddress)));

        // Return the new LSP7SubCollection address
        return lsp7SubCollectionAddress;
    }
}
