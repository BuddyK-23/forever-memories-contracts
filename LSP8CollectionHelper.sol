// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {LSP7SubCollection} from './LSP7SubCollection.sol';

library LSP8CollectionHelper {
    function setDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey,
        bytes memory dataValue
    ) internal {
        // Set data on the LSP7SubCollection
        LSP7SubCollection(payable(address(uint160(uint256(tokenId))))).setData(
            dataKey,
            dataValue
        );
    }

    function getDataForTokenId(
        bytes32 tokenId,
        bytes32 dataKey
    ) internal view returns (bytes memory dataValues) {
        return
            LSP7SubCollection(payable(address(uint160(uint256(tokenId))))).getData(
                dataKey
            );
    }
}
