// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RecommendationGraph.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";
import "../src/RoyaltyDistributor.sol";

contract RecommendationGraphTest is Test {
    RecommendationGraph public graph;
    MusicNFT public musicNFT;
    TuneToken public token;
    RoyaltyDistributor public royaltyDistributor;

    address public constant ADMIN = address(1);
    address public constant ARTIST = address(2);
    address public constant FAN = address(3);
    address public constant USER1 = address(4);
    address public constant USER2 = address(5);

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy contracts
        token = new TuneToken();
        royaltyDistributor = new RoyaltyDistributor(address(token));
        musicNFT = new MusicNFT("ipfs://baseuri/", address(token), address(royaltyDistributor));
        graph = new RecommendationGraph();

        // Setup initial state
        token.transfer(ARTIST, 1_000_000 * 1e18);
        token.transfer(FAN, 1_000_000 * 1e18);

        // Setup roles
        musicNFT.grantRole(musicNFT.MINTER_ROLE(), ARTIST);
        royaltyDistributor.grantRole(royaltyDistributor.DISTRIBUTOR_ROLE(), address(musicNFT));

        vm.stopPrank();
    }

    // Graph Database Integration Tests
    function testAddTrackNode() public {
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000; // 100% share
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
        vm.startPrank(ARTIST);
        bool success = graph.addArtistNode("ipfs://artistMetadata1");
        assertTrue(success);
        assertTrue(graph.artistExists(ARTIST));
        vm.stopPrank();
    }

    // Relationship Tracking Tests
    function testTrackToTrackRelationship() public {
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        uint256 tokenId1 = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        uint256 tokenId2 = musicNFT.createTrackWithCollaborators("ipfs://metadata2", artists, shares, 100, 1 ether);

        bool success1 = graph.addTrackNode(tokenId1, "ipfs://metadata1");
        bool success2 = graph.addTrackNode(tokenId2, "ipfs://metadata2");
        assertTrue(success1 && success2);

        bool success = graph.addTrackToTrackEdge(tokenId1, tokenId2, 80); // 80% similarity
        assertTrue(success);
        assertTrue(graph.tracksAreRelated(tokenId1, tokenId2));
        vm.stopPrank();
    }

    function testUserToTrackInteraction() public {
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        graph.addTrackNode(tokenId, "ipfs://metadata1");
        vm.stopPrank();

        vm.startPrank(USER1);
        bool success = graph.recordUserInteraction(tokenId, 1); // 1 = like
        assertTrue(success);
        assertTrue(graph.hasUserInteracted(USER1, tokenId));
        vm.stopPrank();
    }

    // Recommendation Algorithm Tests
    function testCollaborativeFiltering() public {
        // Setup test data
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;

        // Create three tracks
        uint256 tokenId1 = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        uint256 tokenId2 = musicNFT.createTrackWithCollaborators("ipfs://metadata2", artists, shares, 100, 1 ether);
        uint256 tokenId3 = musicNFT.createTrackWithCollaborators("ipfs://metadata3", artists, shares, 100, 1 ether);

        // Add nodes to the graph
        bool success1 = graph.addTrackNode(tokenId1, "ipfs://metadata1");
        bool success2 = graph.addTrackNode(tokenId2, "ipfs://metadata2");
        bool success3 = graph.addTrackNode(tokenId3, "ipfs://metadata3");
        assertTrue(success1 && success2 && success3);

        // Create relationships between tracks
        bool success4 = graph.addTrackToTrackEdge(tokenId1, tokenId2, 80); // 80% similarity
        bool success5 = graph.addTrackToTrackEdge(tokenId1, tokenId3, 60); // 60% similarity
        assertTrue(success4 && success5);
        vm.stopPrank();

        // Record user interactions
        vm.startPrank(USER1);
        bool success6 = graph.recordUserInteraction(tokenId1, 1); // User1 likes track1
        assertTrue(success6);
        vm.stopPrank();

        vm.startPrank(USER2);
        bool success7 = graph.recordUserInteraction(tokenId1, 1); // User2 likes track1
        bool success8 = graph.recordUserInteraction(tokenId2, 1); // User2 also likes track2
        assertTrue(success7 && success8);
        vm.stopPrank();

        // Test recommendations for user1
        uint256[] memory recommendations = graph.getRecommendationsForUser(USER1);
        assertTrue(recommendations.length > 0, "Should have recommendations");
        assertEq(recommendations[0], tokenId2, "First recommendation should be track2");
        assertEq(recommendations[1], tokenId3, "Second recommendation should be track3");
    }

    // Performance and Security Tests
    function testConcurrentInteractions() public {
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256[] memory tokenIds = new uint256[](5);
        bool[] memory addNodeSuccess = new bool[](5);

        for (uint256 i = 0; i < 5; i++) {
            tokenIds[i] = musicNFT.createTrackWithCollaborators(
                string(abi.encodePacked("ipfs://metadata", vm.toString(i))), artists, shares, 100, 1 ether
            );
            addNodeSuccess[i] =
                graph.addTrackNode(tokenIds[i], string(abi.encodePacked("ipfs://metadata", vm.toString(i))));
            assertTrue(addNodeSuccess[i], "Failed to add track node");
        }
        vm.stopPrank();

        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = address(0x5);

        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            for (uint256 j = 0; j < tokenIds.length; j++) {
                bool success = graph.recordUserInteraction(tokenIds[j], 1);
                assertTrue(success, "Failed to record user interaction");
            }
            vm.stopPrank();
        }

        // Verify all interactions were recorded correctly
        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokenIds.length; j++) {
                assertTrue(graph.hasUserInteracted(users[i], tokenIds[j]), "User interaction not recorded");
            }
        }
    }

    function testAccessControl() public {
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        bool success1 = graph.addTrackNode(tokenId, "ipfs://metadata1");
        assertTrue(success1, "Failed to add track node");
        vm.stopPrank();

        // Non-owner should not be able to remove nodes
        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER1));
        graph.removeTrackNode(tokenId);
        vm.stopPrank();

        // Owner should be able to remove nodes
        vm.startPrank(ADMIN);
        bool success2 = graph.removeTrackNode(tokenId);
        assertTrue(success2, "Failed to remove track node");
        assertFalse(graph.trackExists(tokenId), "Track should not exist after removal");
        vm.stopPrank();
    }
}
