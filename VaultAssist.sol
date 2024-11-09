// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VaultAssist {
    struct Comment {
        address username;
        string content;
        uint256 timestamp; // Added timestamp field
    }

    mapping(bytes32 => Comment[]) public commentsList;
    mapping(bytes32 => string) public longDescription;

    // Constructor
    constructor(address newOwner) {}

    /**
     * @dev Function to add a comment with timestamp
     * @param tokenId The ID of the token to comment on
     * @param content The content of the comment
     */
    function addComment(bytes32 tokenId, string memory content) external {
        commentsList[tokenId].push(
            Comment({
                username: msg.sender,
                content: content,
                timestamp: block.timestamp // Store the current block timestamp
            })
        );
    }

    /**
     * @dev Function to get all comments for a tokenId
     * @param tokenId The ID of the token
     * @return usernames Array of usernames (addresses) who commented
     * @return contents Array of comment contents
     * @return timestamps Array of timestamps when each comment was added
     */
    function getAllComments(bytes32 tokenId)
        external
        view
        returns (address[] memory, string[] memory, uint256[] memory)
    {
        uint256 commentCount = commentsList[tokenId].length;
        address[] memory usernames = new address[](commentCount);
        string[] memory contents = new string[](commentCount);
        uint256[] memory timestamps = new uint256[](commentCount);

        for (uint256 i = 0; i < commentCount; i++) {
            usernames[i] = commentsList[tokenId][i].username;
            contents[i] = commentsList[tokenId][i].content;
            timestamps[i] = commentsList[tokenId][i].timestamp;
        }

        return (usernames, contents, timestamps);
    }

    /**
     * @dev Function to get the count of comments for a tokenId
     * @param tokenId The ID of the token
     * @return The number of comments for the given tokenId
     */
    function getCommentCount(bytes32 tokenId) external view returns (uint256) {
        return commentsList[tokenId].length;
    }

    /**
     * @dev Function to set the long description for a tokenId
     * @param tokenId The ID of the token
     * @param description The long description to set
     */
    function setLongDescription(bytes32 tokenId, string memory description) external {
        longDescription[tokenId] = description;
    }

    /**
     * @dev Function to get the long description for a tokenId
     * @param tokenId The ID of the token
     * @return The long description of the given tokenId
     */
    function getLongDescription(bytes32 tokenId) external view returns (string memory) {
        return longDescription[tokenId];
    }
}
