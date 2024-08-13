// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP8IdentifiableDigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8IdentifiableDigitalAsset.sol";
import {_LSP8_TOKENID_FORMAT_ADDRESS} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_METADATA_KEY} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";
import {LSP8CollectionHelper} from "./LSP8CollectionHelper.sol";
import {LSP8CollectionMinter} from "./LSP8CollectionMinter.sol";


interface ILSP7SubCollection {
    function transfer(address from, address to, uint256 amount, bool force, bytes calldata data) external;
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ForeverMemoryCollection is LSP8IdentifiableDigitalAsset {
    uint256 public rewardAmount;
    uint256 public lsp7TokenType;

    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public mintingDates;
    mapping(bytes32 => address[]) public tokenLikes;
    mapping(bytes32 => mapping(address => bool)) public hasLiked;
    mapping(address => bytes) public encryptedEncryptionKeys;

    event Mint(address indexed minter, address indexed lsp7SubCollectionAddress, uint256 timestamp);
    event Like(address indexed liker, bytes32 indexed tokenId);
    event Transfer(address indexed from, address indexed to, bytes32 indexed tokenId, uint256 amount, bytes data);

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
        bytes memory lsp4MetadataURIOfLSP7_,
        bytes memory encryptedEncryptionKey_
    ) public returns (address lsp7SubCollectionAddress) {
        require(!mintState(), "Minting only once a day");

        lsp7TokenType = 2;

        // Mint new LSP7 sub-collection
        lsp7SubCollectionAddress = LSP8CollectionMinter.mint(
            nameOfLSP7_,
            symbolOfLSP7_,
            lsp7TokenType,
            isNonDivisible_,
            totalSupplyOfLSP7_,
            receiverOfInitialTokens_,
            lsp4MetadataURIOfLSP7_
        );

        // Create a corresponding LSP8 token
        bytes32 tokenId = bytes32(uint256(uint160(lsp7SubCollectionAddress)));
        _mint(address(this), tokenId, true, "");

        lastClaimed[msg.sender] = block.timestamp;
        mintingDates[lsp7SubCollectionAddress] = block.timestamp;

        storeEncryptedKey(lsp7SubCollectionAddress, encryptedEncryptionKey_);

        emit Mint(msg.sender, lsp7SubCollectionAddress, block.timestamp);
    }

    function mintState() internal view returns (bool) {
        return block.timestamp < lastClaimed[msg.sender] + 1 days;
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }

    function storeEncryptedKey(address lsp7contractaddress, bytes memory encryptedEncryptionKey) public {
        encryptedEncryptionKeys[lsp7contractaddress] = encryptedEncryptionKey;
    }

    function getEncryptedKey(address lsp7contractaddress) public view returns (bytes memory) {
        return encryptedEncryptionKeys[lsp7contractaddress];
    }

    function getMintingDate(address lsp7CollectionAddress) public view returns (uint256) {
        return mintingDates[lsp7CollectionAddress];
    }

    function like(bytes32 tokenId) public {
        require(!hasLiked[tokenId][msg.sender], "You can only like a token once");
        tokenLikes[tokenId].push(msg.sender);
        hasLiked[tokenId][msg.sender] = true;

        emit Like(msg.sender, tokenId);
    }

    function getLikes(bytes32 tokenId) public view returns (address[] memory) {
        return tokenLikes[tokenId];
    } 

    function getAuthorizedAmount(bytes32 tokenId) public view returns (uint256) {
        address lsp7SubCollectionAddress = address(uint160(uint256(tokenId)));
        return ILSP7SubCollection(lsp7SubCollectionAddress).allowance(msg.sender, address(this));
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
    
    // New function to transfer LSP7-based NFTs
    function transferNFT(
        bytes32 tokenId,
        address to,
        uint256 amount,
        bytes memory data
    ) public {
        require(amount > 0, "Amount must be greater than zero");

        // Get the LSP7SubCollection address from the tokenId
        address lsp7SubCollectionAddress = address(uint160(uint256(tokenId)));

        // Call the transfer method in LSP7SubCollection contract
        ILSP7SubCollection(lsp7SubCollectionAddress).transfer(msg.sender, to, amount, true, data);
        
        // Emit transfer event specific to LSP7SubCollection transfer
        emit Transfer(msg.sender, to, tokenId, amount, data);
    }
}
