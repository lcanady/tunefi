// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FanEngagement.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";

contract FanEngagementTest is Test {
    FanEngagement public fanEngagement;
    MusicNFT public musicNFT;
    TuneToken public token;
    
    address public admin = address(1);
    address public artist = address(2);
    address public fan = address(3);
    
    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy contracts
        token = new TuneToken();
        musicNFT = new MusicNFT();
        fanEngagement = new FanEngagement(address(token), address(musicNFT));
        
        // Setup initial state
        token.mint(address(fanEngagement), 1000000 * 1e18); // Mint 1M tokens for rewards
        
        vm.stopPrank();
    }
    
    function test_RecordLike() public {
        // Create a track first
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        vm.stopPrank();
        
        // Record like
        vm.startPrank(fan);
        fanEngagement.recordLike(tokenId);
        
        // Check stats
        (
            uint256 totalPoints,
            uint256 totalInteractions,
            uint256 lastInteractionTime,
            bool hasAchievedFirstLike,
            ,
            
        ) = fanEngagement.getUserStats(fan);
        
        assertEq(totalPoints, fanEngagement.LIKE_POINTS());
        assertEq(totalInteractions, 1);
        assertEq(lastInteractionTime, block.timestamp);
        assertTrue(hasAchievedFirstLike);
        vm.stopPrank();
    }
    
    function testFail_DuplicateLike() public {
        // Create a track
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        vm.stopPrank();
        
        // Try to like twice
        vm.startPrank(fan);
        fanEngagement.recordLike(tokenId);
        fanEngagement.recordLike(tokenId); // Should fail
        vm.stopPrank();
    }
    
    function test_RecordShare() public {
        // Create a track
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        vm.stopPrank();
        
        // Record share
        vm.startPrank(fan);
        fanEngagement.recordShare(tokenId);
        
        // Check stats
        (uint256 totalPoints, uint256 totalInteractions,,,,) = fanEngagement.getUserStats(fan);
        
        assertEq(totalPoints, fanEngagement.SHARE_POINTS());
        assertEq(totalInteractions, 1);
        vm.stopPrank();
    }
    
    function test_RecordPurchase() public {
        // Create and purchase a track
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        musicNFT.safeTransferFrom(artist, fan, tokenId, 1, "");
        vm.stopPrank();
        
        // Record purchase
        vm.prank(fan);
        fanEngagement.recordPurchase(tokenId);
        
        // Check stats
        (
            uint256 totalPoints,
            uint256 totalInteractions,
            ,
            ,
            bool hasAchievedFirstPurchase,
            
        ) = fanEngagement.getUserStats(fan);
        
        assertEq(totalPoints, fanEngagement.PURCHASE_POINTS());
        assertEq(totalInteractions, 1);
        assertTrue(hasAchievedFirstPurchase);
    }
    
    function test_ClaimRewards() public {
        // Create and purchase a track to earn points
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        musicNFT.safeTransferFrom(artist, fan, tokenId, 1, "");
        vm.stopPrank();
        
        // Record multiple interactions
        vm.startPrank(fan);
        fanEngagement.recordPurchase(tokenId);
        fanEngagement.recordLike(tokenId);
        fanEngagement.recordShare(tokenId);
        
        // Calculate expected rewards
        uint256 expectedPoints = fanEngagement.PURCHASE_POINTS() + 
                               fanEngagement.LIKE_POINTS() + 
                               fanEngagement.SHARE_POINTS();
        uint256 expectedRewards = (expectedPoints * 1e18) / fanEngagement.POINTS_TO_REWARDS_RATE();
        
        // Get initial balance
        uint256 initialBalance = token.balanceOf(fan);
        
        // Claim rewards
        fanEngagement.claimRewards();
        
        // Verify rewards received
        assertEq(token.balanceOf(fan), initialBalance + expectedRewards);
        
        // Verify points reset
        (uint256 totalPoints,,,,, ) = fanEngagement.getUserStats(fan);
        assertEq(totalPoints, 0);
        vm.stopPrank();
    }
    
    function test_AchievementUnlock() public {
        // Create a track
        vm.startPrank(artist);
        address[] memory artists = new address[](1);
        artists[0] = artist;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators(
            "ipfs://metadata1",
            artists,
            shares,
            100,
            1 ether
        );
        musicNFT.safeTransferFrom(artist, fan, tokenId, 1, "");
        vm.stopPrank();
        
        vm.startPrank(fan);
        
        // Record 10 streams to unlock achievement
        for(uint i = 0; i < 10; i++) {
            fanEngagement.recordStream(tokenId);
        }
        
        // Check achievement
        (,,,,,bool hasAchievedTenInteractions) = fanEngagement.getUserStats(fan);
        assertTrue(hasAchievedTenInteractions);
        vm.stopPrank();
    }
}
