// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SubVault {
    address public owner;

    // Constructor to initialize contract state
    constructor() {
        owner = msg.sender;
    }
}
