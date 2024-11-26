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
    mapping(bytes32 => address[]) public tokenLikes;
    mapping(bytes32 => address[]) public tokenDislikes;
    mapping(bytes32 => mapping(address => bool)) public hasLiked;
    mapping(bytes32 => mapping(address => bool)) public hasDisliked;

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
        returns (
            address[] memory,
            string[] memory,
            uint256[] memory
        )
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
    function setLongDescription(bytes32 tokenId, string memory description)
        external
    {
        longDescription[tokenId] = description;
    }

    /**
     * @dev Function to get the long description for a tokenId
     * @param tokenId The ID of the token
     * @return The long description of the given tokenId
     */
    function getLongDescription(bytes32 tokenId)
        external
        view
        returns (string memory)
    {
        return longDescription[tokenId];
    }

    function like(bytes32 tokenId) external {
        // Check if the user has disliked the token
        if (hasDisliked[tokenId][msg.sender]) {
            // Remove the user from the dislike list
            address[] storage dislikes = tokenDislikes[tokenId];
            for (uint256 i = 0; i < dislikes.length; i++) {
                if (dislikes[i] == msg.sender) {
                    // Swap and pop to remove efficiently
                    dislikes[i] = dislikes[dislikes.length - 1];
                    dislikes.pop();
                    break;
                }
            }
            hasDisliked[tokenId][msg.sender] = false;
        } else {
            // Check if the user has already liked the token
            require(
                !hasLiked[tokenId][msg.sender],
                "You can only like a token once"
            );

            // Add the user to the like list
            tokenLikes[tokenId].push(msg.sender);
            hasLiked[tokenId][msg.sender] = true;
        }
    }

    function getLikes(bytes32 tokenId)
        external
        view
        returns (address[] memory)
    {
        return tokenLikes[tokenId];
    }

    function dislike(bytes32 tokenId) external {
        // Check if the user has liked the token
        if (hasLiked[tokenId][msg.sender]) {
            // Remove the user from the like list
            address[] storage likes = tokenLikes[tokenId];
            for (uint256 i = 0; i < likes.length; i++) {
                if (likes[i] == msg.sender) {
                    // Swap and pop to remove efficiently
                    likes[i] = likes[likes.length - 1];
                    likes.pop();
                    break;
                }
            }
            hasLiked[tokenId][msg.sender] = false;
        } else {
            // Check if the user has already disliked the token
            require(
                !hasDisliked[tokenId][msg.sender],
                "You can only dislike a token once"
            );

            // Add the user to the dislike list
            tokenDislikes[tokenId].push(msg.sender);
            hasDisliked[tokenId][msg.sender] = true;
        }
    }

    function getDislikes(bytes32 tokenId)
        external
        view
        returns (address[] memory)
    {
        return tokenDislikes[tokenId];
    }
}
