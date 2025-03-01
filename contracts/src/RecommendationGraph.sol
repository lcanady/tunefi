// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title RecommendationGraph
 * @dev Implements a decentralized recommendation system using a graph structure
 */
contract RecommendationGraph is Ownable, ReentrancyGuard {
    struct TrackNode {
        string metadataURI;
        bool exists;
        uint256 interactionCount;
    }

    struct ArtistNode {
        string metadataURI;
        bool exists;
        uint256 trackCount;
    }

    struct Edge {
        bool exists;
        uint8 weight; // 0-100 representing strength of relationship
    }

    // Node Storage
    mapping(uint256 => TrackNode) public tracks;
    mapping(address => ArtistNode) public artists;

    // Edge Storage
    mapping(uint256 => mapping(uint256 => Edge)) public trackToTrackEdges;
    mapping(address => mapping(uint256 => bool)) public userInteractions;

    uint256 public _tokenIdCounter;

    // Events
    event TrackNodeAdded(uint256 indexed tokenId, string metadataURI);
    event ArtistNodeAdded(address indexed artist, string metadataURI);
    event TrackEdgeCreated(uint256 indexed fromTrack, uint256 indexed toTrack, uint8 weight);
    event UserInteraction(address indexed user, uint256 indexed tokenId, uint8 interactionType);

    constructor() Ownable(msg.sender) { }

    // Node Management Functions
    function addTrackNode(uint256 tokenId, string memory metadataURI) public returns (bool) {
        require(!tracks[tokenId].exists, "Track already exists");
        tracks[tokenId] = TrackNode({ metadataURI: metadataURI, exists: true, interactionCount: 0 });
        _tokenIdCounter++;
        emit TrackNodeAdded(tokenId, metadataURI);
        return true;
    }

    function addArtistNode(string memory metadataURI) public returns (bool) {
        require(!artists[msg.sender].exists, "Artist already exists");
        artists[msg.sender] = ArtistNode({ metadataURI: metadataURI, exists: true, trackCount: 0 });
        emit ArtistNodeAdded(msg.sender, metadataURI);
        return true;
    }

    function removeTrackNode(uint256 tokenId) public onlyOwner returns (bool) {
        require(tracks[tokenId].exists, "Track does not exist");
        delete tracks[tokenId];
        return true;
    }

    // Edge Management Functions
    function addTrackToTrackEdge(uint256 fromTrack, uint256 toTrack, uint8 weight) public returns (bool) {
        require(tracks[fromTrack].exists && tracks[toTrack].exists, "Tracks must exist");
        require(weight <= 100, "Weight must be between 0 and 100");

        trackToTrackEdges[fromTrack][toTrack] = Edge({ exists: true, weight: weight });

        emit TrackEdgeCreated(fromTrack, toTrack, weight);
        return true;
    }

    function recordUserInteraction(uint256 tokenId, uint8 interactionType) public nonReentrant returns (bool) {
        require(tracks[tokenId].exists, "Track does not exist");
        require(interactionType <= 2, "Invalid interaction type"); // 0=view, 1=like, 2=share

        userInteractions[msg.sender][tokenId] = true;
        tracks[tokenId].interactionCount++;

        emit UserInteraction(msg.sender, tokenId, interactionType);
        return true;
    }

    // Query Functions
    function trackExists(uint256 tokenId) public view returns (bool) {
        return tracks[tokenId].exists;
    }

    function artistExists(address artist) public view returns (bool) {
        return artists[artist].exists;
    }

    function tracksAreRelated(uint256 track1, uint256 track2) public view returns (bool) {
        return trackToTrackEdges[track1][track2].exists;
    }

    function hasUserInteracted(address user, uint256 tokenId) public view returns (bool) {
        return userInteractions[user][tokenId];
    }

    // Recommendation Algorithm
    function getRecommendationsForUser(address user) public view returns (uint256[] memory) {
        // Initialize dynamic arrays for tracking recommendations
        uint256[] memory recommendations = new uint256[](100); // Max recommendations
        uint256[] memory scores = new uint256[](100);
        uint256 count = 0;

        // First pass: Find tracks the user has interacted with
        for (uint256 i = 0; i < _tokenIdCounter; i++) {
            if (!tracks[i].exists) continue;

            if (userInteractions[user][i]) {
                // Look for related tracks
                for (uint256 j = 0; j < _tokenIdCounter; j++) {
                    if (i == j || !tracks[j].exists || userInteractions[user][j]) continue;

                    if (trackToTrackEdges[i][j].exists) {
                        // Calculate recommendation score based on edge weight and interaction count
                        // Use unchecked for weight multiplication since weight is 0-100
                        uint256 score;
                        unchecked {
                            score = uint256(trackToTrackEdges[i][j].weight) * (tracks[j].interactionCount + 1);
                        }

                        // Check if this track is already in recommendations
                        bool found = false;
                        for (uint256 k = 0; k < count; k++) {
                            if (recommendations[k] == j) {
                                // Use unchecked since we know score is limited by weight (0-100)
                                unchecked {
                                    scores[k] += score;
                                }
                                found = true;
                                break;
                            }
                        }

                        // Add new recommendation if not found and there's space
                        if (!found && count < 100) {
                            recommendations[count] = j;
                            scores[count] = score;
                            count++;
                        }
                    }
                }
            }
        }

        // Sort recommendations by score (simple bubble sort)
        for (uint256 i = 0; i < count - 1; i++) {
            for (uint256 j = 0; j < count - i - 1; j++) {
                if (scores[j] < scores[j + 1]) {
                    // Swap scores
                    uint256 tempScore = scores[j];
                    scores[j] = scores[j + 1];
                    scores[j + 1] = tempScore;

                    // Swap recommendations
                    uint256 tempRec = recommendations[j];
                    recommendations[j] = recommendations[j + 1];
                    recommendations[j + 1] = tempRec;
                }
            }
        }

        // Return top recommendations
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = recommendations[i];
        }

        return result;
    }
}
