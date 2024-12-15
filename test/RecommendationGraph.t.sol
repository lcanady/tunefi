// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RecommendationGraph.sol";
import "../src/MusicNFT.sol";

contract RecommendationGraphTest is Test {
    RecommendationGraph public graph;
    MusicNFT public musicNFT;
    address public owner;
    address public artist1;
    address public artist2;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        artist1 = address(0x1);
        artist2 = address(0x2);
        user1 = address(0x3);
        user2 = address(0x4);

        vm.startPrank(owner);
        graph = new RecommendationGraph();
        musicNFT = new MusicNFT();
        vm.stopPrank();
    }

    // Graph Database Integration Tests
    function testAddTrackNode() public {
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000; // 100% share
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100, // initial supply
            1 ether // price
        );
        bool success = graph.addTrackNode(tokenId, "ipfs://metadata1");
        assertTrue(success);
        assertTrue(graph.trackExists(tokenId));
        vm.stopPrank();
    }

    function testAddArtistNode() public {
        vm.startPrank(artist1);
        bool success = graph.addArtistNode("ipfs://artistMetadata1");
        assertTrue(success);
        assertTrue(graph.artistExists(artist1));
        vm.stopPrank();
    }

    // Relationship Tracking Tests
    function testTrackToTrackRelationship() public {
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        uint256 tokenId1 = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        uint256 tokenId2 = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata2",
            artists,
            shares,
            100,
            1 ether
        );
        
        graph.addTrackNode(tokenId1, "ipfs://metadata1");
        graph.addTrackNode(tokenId2, "ipfs://metadata2");
        
        bool success = graph.addTrackToTrackEdge(tokenId1, tokenId2, 80); // 80% similarity
        assertTrue(success);
        assertTrue(graph.tracksAreRelated(tokenId1, tokenId2));
        vm.stopPrank();
    }

    function testUserToTrackInteraction() public {
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        graph.addTrackNode(tokenId, "ipfs://metadata1");
        vm.stopPrank();

        vm.startPrank(user1);
        bool success = graph.recordUserInteraction(tokenId, 1); // 1 = like
        assertTrue(success);
        assertTrue(graph.hasUserInteracted(user1, tokenId));
        vm.stopPrank();
    }

    // Recommendation Algorithm Tests
    function testCollaborativeFiltering() public {
        // Setup test data
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        
        // Create three tracks
        uint256 tokenId1 = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        uint256 tokenId2 = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata2",
            artists,
            shares,
            100,
            1 ether
        );
        uint256 tokenId3 = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata3",
            artists,
            shares,
            100,
            1 ether
        );
        
        // Add nodes to the graph
        graph.addTrackNode(tokenId1, "ipfs://metadata1");
        graph.addTrackNode(tokenId2, "ipfs://metadata2");
        graph.addTrackNode(tokenId3, "ipfs://metadata3");
        
        // Create relationships between tracks
        graph.addTrackToTrackEdge(tokenId1, tokenId2, 80); // 80% similarity
        graph.addTrackToTrackEdge(tokenId1, tokenId3, 60); // 60% similarity
        vm.stopPrank();

        // Record user interactions
        vm.startPrank(user1);
        graph.recordUserInteraction(tokenId1, 1); // User1 likes track1
        vm.stopPrank();

        vm.startPrank(user2);
        graph.recordUserInteraction(tokenId1, 1); // User2 likes track1
        graph.recordUserInteraction(tokenId2, 1); // User2 also likes track2
        vm.stopPrank();

        // Test recommendations for user1
        uint256[] memory recommendations = graph.getRecommendationsForUser(user1);
        assertTrue(recommendations.length > 0, "Should have recommendations");
        assertEq(recommendations[0], tokenId2, "First recommendation should be track2");
        assertEq(recommendations[1], tokenId3, "Second recommendation should be track3");
    }

    // Performance and Security Tests
    function testConcurrentInteractions() public {
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256[] memory tokenIds = new uint256[](5);
        for(uint i = 0; i < 5; i++) {
            tokenIds[i] = musicNFT.createTrackWithCollaborators(
                string(abi.encodePacked("ipfs://metadata", vm.toString(i))),
                artists,
                shares,
                100,
                1 ether
            );
            graph.addTrackNode(tokenIds[i], string(abi.encodePacked("ipfs://metadata", vm.toString(i))));
        }
        vm.stopPrank();

        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = address(0x5);

        for(uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            for(uint j = 0; j < tokenIds.length; j++) {
                graph.recordUserInteraction(tokenIds[j], 1);
            }
            vm.stopPrank();
        }

        // Verify all interactions were recorded correctly
        for(uint i = 0; i < users.length; i++) {
            for(uint j = 0; j < tokenIds.length; j++) {
                assertTrue(graph.hasUserInteracted(users[i], tokenIds[j]));
            }
        }
    }

    function testAccessControl() public {
        vm.startPrank(artist1);
        address[] memory artists = new address[](1);
        artists[0] = artist1;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        graph.addTrackNode(tokenId, "ipfs://metadata1");
        vm.stopPrank();

        // Non-owner should not be able to remove nodes
        vm.startPrank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        graph.removeTrackNode(tokenId);
        vm.stopPrank();

        // Owner should be able to remove nodes
        vm.startPrank(owner);
        bool success = graph.removeTrackNode(tokenId);
        assertTrue(success);
        assertFalse(graph.trackExists(tokenId));
        vm.stopPrank();
    }
}
