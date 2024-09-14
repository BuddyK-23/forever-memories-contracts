// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import {_LSP8_TOKENID_FORMAT_ADDRESS} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_METADATA_KEY} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";
import {LSP8CollectionHelper} from "./LSP8CollectionHelper.sol";
import {LSP8CollectionMinter} from "./LSP8CollectionMinter.sol";

contract Vault is LSP8IdentifiableDigitalAsset {
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public mintingDates;
    mapping(bytes32 => address[]) public tokenLikes;
    mapping(bytes32 => mapping(address => bool)) public hasLiked;
    mapping(address => bytes) public encryptedEncryptionKeys;
    mapping(address => uint256) public totalNFTcounts;
    mapping(address => bytes32[]) public moments;

    event Mint(
        address indexed minter,
        address indexed lsp7SubCollectionAddress,
        uint256 timestamp
    );
    event Like(address indexed liker, bytes32 indexed tokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        uint256 lsp4TokenType_,
        bytes memory lsp4MetadataURI_
    )
        LSP8IdentifiableDigitalAsset(
            name_,
            symbol_,
            newOwner_,
            lsp4TokenType_,
            _LSP8_TOKENID_FORMAT_ADDRESS
        )
    {
        _setData(_LSP4_METADATA_KEY, lsp4MetadataURI_);
    }

    function mint(
        string memory nameOfLSP7_,
        string memory symbolOfLSP7_,
        bool isNonDivisible_,
        uint256 totalSupplyOfLSP7_,
        address receiverOfInitialTokens_,
        bytes memory lsp4MetadataURIOfLSP7_,
        bytes memory encryptedEncryptionKey_,
        address vaultAddress_
    ) external returns (address lsp7SubCollectionAddress) {
        // Mint new LSP7 sub-collection
        lsp7SubCollectionAddress = LSP8CollectionMinter.mint(
            nameOfLSP7_,
            symbolOfLSP7_,
            2,
            isNonDivisible_,
            totalSupplyOfLSP7_,
            receiverOfInitialTokens_,
            lsp4MetadataURIOfLSP7_
        );

        // Mint corresponding LS P8 token
        bytes32 tokenId = bytes32(uint256(uint160(lsp7SubCollectionAddress)));
        _mint(vaultAddress_, tokenId, true, "");

        lastClaimed[msg.sender] = block.timestamp;
        mintingDates[lsp7SubCollectionAddress] = block.timestamp;

        storeEncryptedKey(lsp7SubCollectionAddress, encryptedEncryptionKey_);
        totalNFTcounts[vaultAddress_]++;
        moments[lsp7SubCollectionAddress].push(tokenId);

        // Check if the user is eligible for a reward
        if (canClaimReward(msg.sender)) {
            lastClaimed[msg.sender] = block.timestamp;
            // Handle reward distribution here (e.g., tokens, points, etc.)
        }
        
        emit Mint(msg.sender, lsp7SubCollectionAddress, block.timestamp);
    }

    function canClaimReward(address user) public view returns (bool) {
        return block.timestamp >= lastClaimed[user] + 1 days;
    }

    function getAllMoments(address vaultAddress) external view returns (bytes32[] memory) {
        return moments[vaultAddress];
    }
 
    function storeEncryptedKey(address lsp7SubCollectionAddress, bytes memory encryptedEncryptionKey) public {
        encryptedEncryptionKeys[lsp7SubCollectionAddress] = encryptedEncryptionKey;
    }

    function getEncryptedKey(address lsp7SubCollectionAddress) public view returns (bytes memory) {
        return encryptedEncryptionKeys[lsp7SubCollectionAddress];
    }

    function getMintingDate(address lsp7SubCollectionAddress) public view returns (uint256) {
        return mintingDates[lsp7SubCollectionAddress];
    }

    function like(bytes32 tokenId) external {
        require(!hasLiked[tokenId][msg.sender], "You can only like a token once");

        tokenLikes[tokenId].push(msg.sender);
        hasLiked[tokenId][msg.sender] = true;

        emit Like(msg.sender, tokenId);
    }

    function getLikes(bytes32 tokenId) external view returns (address[] memory) {
        return tokenLikes[tokenId];
    }

    function getNFTcounts(address vaultAddress_) external view returns (uint256) {
        return totalNFTcounts[vaultAddress_];
    }

    function transferMoment(
        bytes32 tokenId, 
        address currentVaultAddress, 
        address newVaultAddress
    ) external {
        require(ownerOf(tokenId) == currentVaultAddress, "Current vault doesn't own this moment");
        require(currentVaultAddress == msg.sender, "Only the current vault can initiate the transfer");

        // Transfer the LSP8 token (moment) to the new vault
        _transfer(currentVaultAddress, newVaultAddress, tokenId, true, "");

        // Handle transferring any related LSP7 sub-collection ownership logic
        // You can implement this based on how you're handling LSP7 tokens
        transferLSP7SubCollection(tokenId, currentVaultAddress, newVaultAddress);

        // Update total NFT count for both vaults
        totalNFTcounts[currentVaultAddress]--;
        totalNFTcounts[newVaultAddress]++;

        // Update moments mapping for both vaults
        _removeMoment(currentVaultAddress, tokenId);
        moments[newVaultAddress].push(tokenId);
    }

    function transferLSP7SubCollection(
        bytes32 tokenId,
        address currentVaultAddress,
        address newVaultAddress
    ) internal {
        // Assuming the tokenId corresponds to the LSP7 sub-collection address
        address lsp7SubCollectionAddress = address(uint160(uint256(tokenId)));

        // Transfer the LSP7 sub-collection to the new vault
        // (This will depend on how the LSP7 token is being managed)
        LSP8CollectionMinter.transferLSP7(lsp7SubCollectionAddress, currentVaultAddress, newVaultAddress);
    }

    function _removeMoment(address vaultAddress, bytes32 tokenId) internal {
        uint256 length = moments[vaultAddress].length;
        for (uint256 i = 0; i < length; i++) {
            if (moments[vaultAddress][i] == tokenId) {
                moments[vaultAddress][i] = moments[vaultAddress][length - 1];
                moments[vaultAddress].pop();
                break;
            }
        }
    }


    function _setDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal override {
        LSP8CollectionHelper.setDataForTokenId(tokenId, dataKey, dataValue);
        emit TokenIdDataChanged(tokenId, dataKey, dataValue);
    }

    function _getDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey
    ) internal view override returns (bytes memory dataValues) {
        return LSP8CollectionHelper.getDataForTokenId(tokenId, dataKey);
    }
}