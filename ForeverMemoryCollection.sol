// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import {_LSP8_TOKENID_FORMAT_ADDRESS} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_METADATA_KEY} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";
import {LSP8CollectionHelper} from "./LSP8CollectionHelper.sol";
import {LSP8CollectionMinter} from "./LSP8CollectionMinter.sol";

contract ForeverMemoryCollection is LSP8IdentifiableDigitalAsset {
    uint256 public rewardAmount;
    uint256 public totalMintCount; // Variable to store total mint count
    mapping(address => uint256) public lastClaimed;
    address[] public mintedAddresses; // Array to store minted addresses
    mapping(address => uint256) public mintingDates; // Mapping to store minting dates

    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        uint256 lsp4TokenType_,
        bytes memory lsp4MetadataURI_,
        uint256 _rewardAmount
    )
        LSP8IdentifiableDigitalAsset(
            name_,
            symbol_,
            newOwner_,
            lsp4TokenType_,
            _LSP8_TOKENID_FORMAT_ADDRESS
        )
    {
        // set the lsp4MetadataURI
        _setData(_LSP4_METADATA_KEY, lsp4MetadataURI_);
        rewardAmount = _rewardAmount;
    }

    function mint(
        string memory nameOfLSP7_,
        string memory symbolOfLSP7_,
        uint256 lsp4TokenType_,
        bool isNonDivisible_,
        uint256 totalSupplyOfLSP7_,
        address receiverOfInitialTokens_,
        bytes memory lsp4MetadataURIOfLSP7_
    ) public returns (address lsp7SubCollectionAddress) {
        require(!mintState(), "Minting only once a day");
        lsp7SubCollectionAddress = LSP8CollectionMinter.mint(
            nameOfLSP7_,
            symbolOfLSP7_,
            lsp4TokenType_,
            isNonDivisible_,
            totalSupplyOfLSP7_,
            receiverOfInitialTokens_,
            lsp4MetadataURIOfLSP7_
        );

        // Increment total mint count
        totalMintCount++;

        // Convert the address of the LSP7SubCollection to bytes32 to use it as tokenId
        bytes32 tokenId = bytes32(uint256(uint160(lsp7SubCollectionAddress)));

        // Mint the token
        _mint(address(this), tokenId, true, "");

        // Record the last claimed time for the minter
        lastClaimed[receiverOfInitialTokens_] = block.timestamp;

        // Store the minted address
        mintedAddresses.push(lsp7SubCollectionAddress);

        // Store the minting date
        mintingDates[lsp7SubCollectionAddress] = block.timestamp;
    }

    function mintState() internal view returns (bool) {
        if (block.timestamp >= lastClaimed[msg.sender] + 86400) {
            return false;
        }
        return true;
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }

    // Function to get the minting date of a specific LSP7 collection
    function getMintingDate(address lsp7CollectionAddress) public view returns (uint256) {
        return mintingDates[lsp7CollectionAddress];
    }

    // Override the _setDataForTokenId function to set the data on the LSP7SubCollection itself
    function _setDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal override {
        LSP8CollectionHelper.setDataForTokenId(tokenId, dataKey, dataValue);
        emit TokenIdDataChanged(tokenId, dataKey, dataValue);
    }

    // Override the _getDataForTokenId function to get the data from the LSP7SubCollection itself
    function _getDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey
    ) internal view override returns (bytes memory dataValues) {
        return LSP8CollectionHelper.getDataForTokenId(tokenId, dataKey);
    }
}
