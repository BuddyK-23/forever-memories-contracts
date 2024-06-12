// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP7DigitalAsset} from "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/LSP7DigitalAsset.sol";
import {LSP4DigitalAssetMetadata} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4DigitalAssetMetadata.sol";
import {_LSP4_SUPPORTED_STANDARDS_KEY, _LSP4_SUPPORTED_STANDARDS_VALUE, _LSP4_METADATA_KEY} from "@lukso/lsp-smart-contracts/contracts/LSP4DigitalAssetMetadata/LSP4Constants.sol";
import {_LSP8_REFERENCE_CONTRACT} from "@lukso/lsp-smart-contracts/contracts/LSP8IdentifiableDigitalAsset/LSP8Constants.sol";

contract LSP7SubCollection is LSP7DigitalAsset {
    constructor(
        string memory name_,
        string memory symbol_,
        address newOwner_,
        address receiverOfInitialTokens_,
        uint256 lsp4TokenType_,
        bool isNonDivisible_,
        uint256 totalSupply_,
        bytes memory lsp4MetadataURI_
    )
        LSP7DigitalAsset(
            name_,
            symbol_,
            newOwner_,
            lsp4TokenType_,
            isNonDivisible_
        )
    {

        // set LSP8ReferenceContract
        LSP4DigitalAssetMetadata._setData(
            _LSP8_REFERENCE_CONTRACT,
            abi.encodePacked(
                msg.sender,
                bytes32(uint256(uint160(address(this))))
            )
        );

        // set the lsp4MetadataURI
        _setData(_LSP4_METADATA_KEY, lsp4MetadataURI_);

        // mint all tokens to the receiver of the initial tokens
        _mint(receiverOfInitialTokens_, totalSupply_, true, "");
    }

    // override the _setData function so that the LSP8ReferenceContract is not editable
    function _setData(
        bytes32 dataKey,
        bytes memory dataValue
    ) internal override {
        require(
            dataKey != _LSP8_REFERENCE_CONTRACT,
            "LSP8ReferenceContractNotEditable"
        );
        LSP4DigitalAssetMetadata._setData(dataKey, dataValue);
    }
}
