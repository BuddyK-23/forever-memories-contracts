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
        require(!canMint(), "Minting allowed only once a day");

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

        // Mint corresponding LSP8 token
        bytes32 tokenId = bytes32(uint256(uint160(lsp7SubCollectionAddress)));
        _mint(vaultAddress_, tokenId, true, "");

        lastClaimed[msg.sender] = block.timestamp;
        mintingDates[lsp7SubCollectionAddress] = block.timestamp;

        storeEncryptedKey(lsp7SubCollectionAddress, encryptedEncryptionKey_);
        totalNFTcounts[vaultAddress_]++;

        emit Mint(msg.sender, lsp7SubCollectionAddress, block.timestamp);
    }

    function canMint() public view returns (bool) {
        return block.timestamp < lastClaimed[msg.sender] + 1 days;
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