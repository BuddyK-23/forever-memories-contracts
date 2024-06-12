// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/presets/LSP7Mintable.sol";
import "@lukso/lsp-smart-contracts/contracts/LSP7DigitalAsset/extensions/LSP7Burnable.sol";

contract FMT is LSP7Mintable, LSP7Burnable {
    constructor(
        string memory tokenName_,
        string memory tokenSymbol_,
        address tokenContractOwner_,
        uint256 tokenDecimals,
        uint256 tokenAmount_,
        uint256 lsp4TokenType_,
        bool isNonDivisible_
    )
        LSP7Mintable(
            tokenName_,
            tokenSymbol_,
            tokenContractOwner_,
            lsp4TokenType_,
            isNonDivisible_
        )
    {
        {
            // your custom smart contract logic ...

            mint(
                msg.sender, // deployer will receive initial tokens
                tokenAmount_ * tokenDecimals ** decimals(), // will mint 20k tokens
                true, // force parameter
                "" // optional transaction data
            );
        }
    }

    function burnTokens(address from, uint256 amount) public {
        // Custom logic before burning, if any
        burn(from, amount, "");
    }
}
