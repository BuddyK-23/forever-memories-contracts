// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import LSP8Mintable from LUKSO's smart contracts
import {LSP8Mintable} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/presets/LSP8Mintable.sol";
import "@erc725/smart-contracts/contracts/ERC725Y.sol";

// Constants
import {_LSP8_TOKENID_FORMAT_NUMBER} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";
import {_LSP4_TOKEN_TYPE_NFT} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";

// Vault contract that inherits from LSP8Mintable
contract Vault is LSP8Mintable {
    mapping(address => uint256) public lastClaimed;
    mapping(address => uint256) public mintingDates;
    mapping(bytes32 => address[]) public tokenLikes;
    mapping(bytes32 => mapping(address => bool)) public hasLiked;
    mapping(address => bytes) public encryptedEncryptionKeys;
    mapping(address => uint256) public totalNFTcounts;
    mapping(address => bytes32[]) public moments;
    mapping(bytes32 => address) public momentOwners;

    event Like(address indexed liker, bytes32 indexed tokenId);

    // Constructor to set name, symbol, and contract owner
    constructor(
        string memory LSP8CollectionName,
        string memory LSP8CollectionSymbol,
        address newOwner
    )
        LSP8Mintable(
            LSP8CollectionName,
            LSP8CollectionSymbol,
            newOwner,
            _LSP4_TOKEN_TYPE_NFT,
            _LSP8_TOKENID_FORMAT_NUMBER
        )
    {}

    function mintMoment(
        address momentAddress,
        address vaultAddress,
        bytes32 LSP4MetadataKey,
        bytes memory lsp4MetadataURI,
        bytes memory encryptedEncryptionKey
    ) public {
        // Use the address of the new contract as a unique tokenId
        bytes32 tokenId = bytes32(uint256(uint160(momentAddress)));

        // // Set metadata for the newly minted token
        _setDataForTokenId(tokenId, LSP4MetadataKey, lsp4MetadataURI);

        // Mint the NFT without access restriction
        _mint(vaultAddress, tokenId, true, "");

        lastClaimed[msg.sender] = block.timestamp;
        mintingDates[momentAddress] = block.timestamp;

        storeEncryptedKey(momentAddress, encryptedEncryptionKey);
        totalNFTcounts[vaultAddress]++;
        moments[vaultAddress].push(tokenId);
        momentOwners[tokenId] = msg.sender;
    }

    function canMint() public view returns (bool) {
        return block.timestamp < lastClaimed[msg.sender] + 1 days;
    }

    function getAllMoments(address vaultAddress)
        external
        view
        returns (bytes32[] memory)
    {
        return moments[vaultAddress];
    }

    function storeEncryptedKey(
        address momentAddress,
        bytes memory encryptedEncryptionKey
    ) public {
        encryptedEncryptionKeys[momentAddress] = encryptedEncryptionKey;
    }

    function getEncryptedKey(address momentAddress)
        public
        view
        returns (bytes memory)
    {
        return encryptedEncryptionKeys[momentAddress];
    }

    function getMintingDate(address momentAddress)
        public
        view
        returns (uint256)
    {
        return mintingDates[momentAddress];
    }

    function like(bytes32 tokenId) external {
        require(
            !hasLiked[tokenId][msg.sender],
            "You can only like a token once"
        );

        tokenLikes[tokenId].push(msg.sender);
        hasLiked[tokenId][msg.sender] = true;

        emit Like(msg.sender, tokenId);
    }

    function getLikes(bytes32 tokenId)
        external
        view
        returns (address[] memory)
    {
        return tokenLikes[tokenId];
    }

    function getNFTcounts(address vaultAddress_)
        external
        view
        returns (uint256)
    {
        return totalNFTcounts[vaultAddress_];
    }
}
