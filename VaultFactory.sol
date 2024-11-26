// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SubVault.sol";

contract VaultFactory {
    address public owner;

    struct User {
        address memberAddress;
        uint8 permission; // Optimized for packing
        uint256 creationTime; // Stores the time the user was added to the vault
    }

    struct FMVault {
        uint8 vaultMode;
        User[] userLists;
        string title; // Store the actual title string
        string description; // Store the actual description string
        string image; // Store the actual image URI string
        uint256 rewardAmount;
        uint8[] categories;
    }

    mapping(address => FMVault) public vaults;
    mapping(uint8 => address[]) public categoryToVaults; // Mapping from category to vault addresses (changed from bytes32 to uint8)
    mapping(address => address) public vaultsOwner;

    address[] public publicVaults; // Array to store public vault addresses
    address[] public privateVaults; // Array to store private vault addresses

    constructor() {
        owner = msg.sender;
    }

    function createVault(
        string memory title_,
        string memory description_,
        string memory imageURI_,
        uint256 rewardAmount_,
        uint8 vaultMode_, // Reduced to uint8 for efficiency
        uint8[] memory categories_ // Add categories parameter (changed to uint8[])
    ) external returns (address) {
        SubVault newContract = new SubVault();

        // Store the vault metadata and details in FMVault struct
        FMVault storage newFMVault = vaults[address(newContract)];
        newFMVault.vaultMode = vaultMode_;
        newFMVault.title = title_; // Store the plain title string
        newFMVault.description = description_; // Store the plain description string
        newFMVault.image = imageURI_; // Store the plain image URI string
        newFMVault.rewardAmount = rewardAmount_; // Set the reward amount for the vault
        newFMVault.categories = categories_; // Store the categories

        // Add the vault to public or private list based on mode
        if (vaultMode_ == 0) {
            // public vault
            publicVaults.push(address(newContract));
            // Update the category index
        } else if (vaultMode_ == 1) {
            // private vault
            privateVaults.push(address(newContract));
        }

        for (uint256 i = 0; i < categories_.length; i++) {
            categoryToVaults[categories_[i]].push(address(newContract));
        }

        // vault owner
        newFMVault.userLists.push(
            User({
                memberAddress: msg.sender,
                permission: 2, // mint permission, 1: yes, 0: no, 2:owner
                creationTime: block.timestamp // Store the current time
            })
        );
        vaultsOwner[address(newContract)] = msg.sender;

        return address(this);
    }

    function getVaultMetadata(address vaultAddress)
        external
        view
        returns (
            string memory title,
            string memory description,
            string memory imageURI,
            uint8[] memory categories,
            uint256 memberCount,
            address vaultOwner,
            uint8 vaultMode
        )
    {
        FMVault storage vault = vaults[vaultAddress];

        title = vault.title; // Return the plain title string
        description = vault.description; // Return the plain description string
        imageURI = vault.image; // Return the plain image URI string
        categories = vault.categories; // Retrieve categories
        memberCount = vault.userLists.length; // Retrieve user count
        vaultOwner = vaultsOwner[vaultAddress];
        vaultMode = vault.vaultMode;
    }

    function joinVault(address vaultAddress) external {
        FMVault storage vault = vaults[vaultAddress];

        // Only allow joining if the vault is public (vaultMode == 0)
        require(vault.vaultMode == 0, "This vault is not a public vault");

        vault.userLists.push(
            User({
                memberAddress: msg.sender,
                permission: 1, // mint permission, 1: yes, 0: no
                creationTime: block.timestamp // Store the current time
            })
        );
    }

    function leaveVault(address vaultAddress) external {
        FMVault storage vault = vaults[vaultAddress];

        // Ensure the vault owner cannot leave without transferring ownership
        require(
            vaultsOwner[vaultAddress] != msg.sender,
            "Vault owner cannot leave the vault. Transfer ownership first."
        );

        bool found = false;

        // Find the index of the user in the userLists array
        for (uint256 i = 0; i < vault.userLists.length; i++) {
            if (vault.userLists[i].memberAddress == msg.sender) {
                found = true;

                // Remove the user by shifting the array
                vault.userLists[i] = vault.userLists[
                    vault.userLists.length - 1
                ]; // Move the last element to the current index
                vault.userLists.pop(); // Remove the last element (now duplicated)
                break;
            }
        }

        require(found, "User is not a member of this vault");
    }

    function inviteMember(address vaultAddress, address invitedMember)
        external
    {
        FMVault storage vault = vaults[vaultAddress];

        // Ensure only the vault owner can invite members to a private vault
        require(vault.vaultMode == 1, "This is not a private vault");
        require(
            msg.sender == vaultsOwner[vaultAddress],
            "Only the vault owner can invite members"
        );

        // Add the invited member to the user list
        vault.userLists.push(
            User({
                memberAddress: invitedMember,
                permission: 1, // mint permission, 1: yes, 0: no
                creationTime: block.timestamp // Store the current time
            })
        );
    }

    function getVaultMembers(address vaultAddress)
        external
        view
        returns (address[] memory)
    {
        FMVault storage vault = vaults[vaultAddress];
        uint256 memberCount = vault.userLists.length; // Get the number of members
        address[] memory members = new address[](memberCount); // Create an array to store the member addresses

        for (uint256 i = 0; i < memberCount; i++) {
            members[i] = vault.userLists[i].memberAddress; // Populate the array with member addresses
        }

        return members; // Return the array of member addresses
    }

    function getUnjoinedPublicVaults(address userAddress)
        external
        view
        returns (address[] memory)
    {
        address[] memory tempVaults = new address[](publicVaults.length); // Temporary array to store the unjoined vault addresses
        uint256 count = 0; // Counter for the unjoined vaults

        for (uint256 i = 0; i < publicVaults.length; i++) {
            address vaultAddress = publicVaults[i];
            FMVault storage vault = vaults[vaultAddress];
            bool isJoined = false;

            // Check if the user is a member of this vault
            for (uint256 j = 0; j < vault.userLists.length; j++) {
                if (vault.userLists[j].memberAddress == userAddress) {
                    isJoined = true; // User has joined this vault
                    break;
                }
            }

            // If the user has not joined, add the vault to the temp array
            if (!isJoined) {
                tempVaults[count] = vaultAddress;
                count++;
            }
        }

        // Create a new array of the correct size to return
        address[] memory unjoinedVaults = new address[](count);
        for (uint256 k = 0; k < count; k++) {
            unjoinedVaults[k] = tempVaults[k];
        }

        return unjoinedVaults;
    }

    function getRewardAmount(address vaultAddress)
        public
        view
        returns (uint256)
    {
        FMVault storage vault = vaults[vaultAddress];
        return vault.rewardAmount;
    }

    function updateRewardAmount(address vaultAddress, uint256 newAmount)
        public
    {
        require(msg.sender == owner, "Only the owner can perform this action");
        FMVault storage vault = vaults[vaultAddress];
        vault.rewardAmount = newAmount;
    }

    function getVaultsByCategory(
        uint8 category,
        address userAddress,
        uint8 vaultMode, // if 0 public, 1 private
        bool includeJoined // If true, fetch joined vaults; if false, fetch unjoined vaults
    ) external view returns (address[] memory) {
        // If category is 0, use all public vaults; otherwise, filter by category
        address[] memory tempVaults = category == 0
            ? publicVaults
            : categoryToVaults[category];

        address[] memory filteredVaults = new address[](tempVaults.length); // Temporary array for storing filtered vaults
        uint256 count = 0; // Counter for valid vaults

        for (uint256 i = 0; i < tempVaults.length; i++) {
            address vaultAddress = tempVaults[i];
            FMVault storage vault = vaults[vaultAddress];

            // Check if the vault matches the desired mode
            if (vault.vaultMode != vaultMode) {
                continue;
            }

            // Check if the user is the owner of the vault; if true, skip the vault
            if (vaultsOwner[vaultAddress] == userAddress) {
                continue;
            }

            // Determine if the user is a member of this vault
            bool isJoined = false;
            for (uint256 j = 0; j < vault.userLists.length; j++) {
                if (vault.userLists[j].memberAddress == userAddress) {
                    isJoined = true;
                    break;
                }
            }

            // Add the vault to the filteredVaults array based on the includeJoined flag
            if (isJoined == includeJoined) {
                filteredVaults[count] = vaultAddress;
                count++;
            }
        }

        // Create a new array of the correct size to return
        address[] memory resultVaults = new address[](count);
        for (uint256 k = 0; k < count; k++) {
            resultVaults[k] = filteredVaults[k];
        }

        return resultVaults;
    }

    function getAllPublicVaults() external view returns (address[] memory) {
        return publicVaults;
    }

    function getAllPrivateVaults() external view returns (address[] memory) {
        return privateVaults;
    }

    function getVaultsOwnedByUser(
        address userAddress,
        bool vaultMode // Pass `true` for public vaults, `false` for private vaults
    ) external view returns (address[] memory) {
        // Choose the appropriate vault list based on the flag
        address[] storage vaultList = vaultMode ? publicVaults : privateVaults;

        address[] memory tempVaults = new address[](vaultList.length); // Temporary array to store vault addresses
        uint256 count = 0; // Counter for the vaults owned by the user

        for (uint256 i = 0; i < vaultList.length; i++) {
            address vaultAddress = vaultList[i];

            // Check if the vault is owned by the user
            if (vaultsOwner[vaultAddress] == userAddress) {
                tempVaults[count] = vaultAddress;
                count++;
            }
        }

        // Create a new array of the correct size to return
        address[] memory ownedVaults = new address[](count);
        for (uint256 k = 0; k < count; k++) {
            ownedVaults[k] = tempVaults[k];
        }

        return ownedVaults;
    }

    // all public vaults that I created or joint
    function getVaultsByUser(
        address userAddress,
        bool vaultMode // Pass `true` for public vaults, `false` for private vaults
    ) external view returns (address[] memory) {
        // Choose the appropriate vault list based on the flag
        address[] storage vaultList = vaultMode ? publicVaults : privateVaults;

        address[] memory tempVaults = new address[](vaultList.length); // Temporary array to store the vault addresses
        uint256 count = 0; // Counter for the vaults the user has joined or been invited to

        for (uint256 i = 0; i < vaultList.length; i++) {
            address vaultAddress = vaultList[i];
            FMVault storage vault = vaults[vaultAddress];

            // Check if the user is a member of this vault
            for (uint256 j = 0; j < vault.userLists.length; j++) {
                if (
                    vault.userLists[j].memberAddress == userAddress &&
                    vault.userLists[j].permission != 2
                ) {
                    // Add to the temp array if user is a member
                    tempVaults[count] = vaultAddress;
                    count++;
                    break; // No need to check further once the user is found in the userLists
                }
            }
        }

        // Create a new array of the correct size to return
        address[] memory userVaults = new address[](count);
        for (uint256 k = 0; k < count; k++) {
            userVaults[k] = tempVaults[k];
        }

        return userVaults;
    }

    // burn vault
    function burnVault(address vaultAddress) external {
        // Ensure the sender is the owner of the vault
        require(
            vaultsOwner[vaultAddress] == owner,
            "Only the vault owner can delete the vault."
        );

        FMVault storage vault = vaults[vaultAddress];

        // Remove the vault from the public or private vaults array
        if (vault.vaultMode == 0) {
            // public vault
            _removeVaultFromList(publicVaults, vaultAddress);
        } else if (vault.vaultMode == 1) {
            // private vault
            _removeVaultFromList(privateVaults, vaultAddress);
        }

        // Remove the vault from the category mappings
        for (uint256 i = 0; i < vault.categories.length; i++) {
            _removeVaultFromCategory(vault.categories[i], vaultAddress);
        }

        // Delete the vault data from the mappings
        delete vaults[vaultAddress];
        delete vaultsOwner[vaultAddress];
    }

    function _removeVaultFromList(
        address[] storage vaultList,
        address vaultAddress
    ) internal {
        for (uint256 i = 0; i < vaultList.length; i++) {
            if (vaultList[i] == vaultAddress) {
                vaultList[i] = vaultList[vaultList.length - 1]; // Move the last element to the current index
                vaultList.pop(); // Remove the last element
                break;
            }
        }
    }

    function _removeVaultFromCategory(uint8 category, address vaultAddress)
        internal
    {
        address[] storage categoryVaults = categoryToVaults[category];
        for (uint256 i = 0; i < categoryVaults.length; i++) {
            if (categoryVaults[i] == vaultAddress) {
                categoryVaults[i] = categoryVaults[categoryVaults.length - 1]; // Move the last element to the current index
                categoryVaults.pop(); // Remove the last element
                break;
            }
        }
    }

    function removeMember(address vaultAddress, address memberAddress)
        external
    {
        FMVault storage vault = vaults[vaultAddress];

        // Ensure only the vault owner can remove a member
        require(
            msg.sender == vaultsOwner[vaultAddress],
            "Only the vault owner can remove members"
        );

        bool memberRemoved = false;

        // Iterate through the members list to find and remove the member
        for (uint256 i = 0; i < vault.userLists.length; i++) {
            if (vault.userLists[i].memberAddress == memberAddress) {
                // Remove the member by replacing with the last element and then popping
                vault.userLists[i] = vault.userLists[
                    vault.userLists.length - 1
                ];
                vault.userLists.pop();
                memberRemoved = true;
                break;
            }
        }

        require(memberRemoved, "Member not found in the vault");
    }
}
