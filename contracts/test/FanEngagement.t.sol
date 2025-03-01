// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/FanEngagement.sol";
import "../src/MusicNFT.sol";
import "../src/TuneToken.sol";
import "../src/RoyaltyDistributor.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract FanEngagementTest is Test, ERC1155Holder {
    FanEngagement public fanEngagement;
    MusicNFT public musicNFT;
    TuneToken public token;
    RoyaltyDistributor public royaltyDistributor;

    address public constant ADMIN = address(1);
    address public constant ARTIST = address(2);
    address public constant FAN = address(3);

    function setUp() public {
        vm.startPrank(ADMIN);

        // Deploy contracts
        token = new TuneToken();
        royaltyDistributor = new RoyaltyDistributor(address(token));
        musicNFT = new MusicNFT("ipfs://baseuri/", address(token), address(royaltyDistributor));
        fanEngagement = new FanEngagement(address(token), address(musicNFT));

        // Setup initial state
        token.transfer(address(fanEngagement), 1_000_000 * 1e18); // Transfer tokens for rewards
        token.transfer(FAN, 1_000_000 * 1e18); // Give FAN some tokens

        // Setup roles for testing
        musicNFT.grantRole(musicNFT.MINTER_ROLE(), ARTIST);
        royaltyDistributor.grantRole(royaltyDistributor.DISTRIBUTOR_ROLE(), address(musicNFT));

        vm.stopPrank();

        // Approve token transfers for FAN
        vm.prank(FAN);
        token.approve(address(fanEngagement), type(uint256).max);
    }

    function test_RecordLike() public {
        // Create a track first
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        vm.stopPrank();

        // Record like
        vm.startPrank(FAN);
        fanEngagement.recordLike(tokenId);

        // Check stats
        (uint256 totalPoints, uint256 totalInteractions, uint256 lastInteractionTime, bool hasAchievedFirstLike,,) =
            fanEngagement.getUserStats(FAN);

        assertEq(totalPoints, fanEngagement.LIKE_POINTS());
        assertEq(totalInteractions, 1);
        assertEq(lastInteractionTime, block.timestamp);
        assertTrue(hasAchievedFirstLike);
        vm.stopPrank();
    }

    function testFail_DuplicateLike() public {
        // Create a track
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        vm.stopPrank();

        // Try to like twice
        vm.startPrank(FAN);
        fanEngagement.recordLike(tokenId);
        fanEngagement.recordLike(tokenId); // Should fail
        vm.stopPrank();
    }

    function test_RecordShare() public {
        // Create a track
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        vm.stopPrank();

        // Record share
        vm.startPrank(FAN);
        fanEngagement.recordShare(tokenId);

        // Check stats
        (uint256 totalPoints, uint256 totalInteractions,,,,) = fanEngagement.getUserStats(FAN);

        assertEq(totalPoints, fanEngagement.SHARE_POINTS());
        assertEq(totalInteractions, 1);
        vm.stopPrank();
    }

    function test_RecordPurchase() public {
        // Create and purchase a track
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        musicNFT.safeTransferFrom(ARTIST, FAN, tokenId, 1, "");
        vm.stopPrank();

        // Record purchase
        vm.startPrank(FAN);
        fanEngagement.recordPurchase(tokenId);

        // Check stats
        (uint256 totalPoints, uint256 totalInteractions,,, bool hasAchievedFirstPurchase,) =
            fanEngagement.getUserStats(FAN);

        assertEq(totalPoints, fanEngagement.PURCHASE_POINTS());
        assertEq(totalInteractions, 1);
        assertTrue(hasAchievedFirstPurchase);
        vm.stopPrank();
    }

    function test_ClaimRewards() public {
        // Create and purchase a track to earn points
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        musicNFT.safeTransferFrom(ARTIST, FAN, tokenId, 1, "");
        vm.stopPrank();

        // Record multiple interactions
        vm.startPrank(FAN);
        fanEngagement.recordPurchase(tokenId);
        fanEngagement.recordLike(tokenId);
        fanEngagement.recordShare(tokenId);

        // Calculate expected rewards
        uint256 expectedPoints =
            fanEngagement.PURCHASE_POINTS() + fanEngagement.LIKE_POINTS() + fanEngagement.SHARE_POINTS();
        uint256 expectedRewards = (expectedPoints * 1e18) / fanEngagement.POINTS_TO_REWARDS_RATE();

        // Get initial balance
        uint256 initialBalance = token.balanceOf(FAN);

        // Claim rewards
        fanEngagement.claimRewards();

        // Verify rewards received
        assertEq(token.balanceOf(FAN), initialBalance + expectedRewards);

        // Verify points reset
        (uint256 totalPoints,,,,,) = fanEngagement.getUserStats(FAN);
        assertEq(totalPoints, 0);
        vm.stopPrank();
    }

    function test_AchievementUnlock() public {
        // Create a track
        vm.startPrank(ARTIST);
        address[] memory artists = new address[](1);
        artists[0] = ARTIST;
        uint256[] memory shares = new uint256[](1);
        shares[0] = 10_000;
        uint256 tokenId = musicNFT.createTrackWithCollaborators("ipfs://metadata1", artists, shares, 100, 1 ether);
        musicNFT.safeTransferFrom(ARTIST, FAN, tokenId, 1, "");
        vm.stopPrank();

        vm.startPrank(FAN);

        // Record 10 streams to unlock achievement
        for (uint256 i = 0; i < 10; i++) {
            fanEngagement.recordStream(tokenId);
        }

        // Check achievement
        (,,,,, bool hasAchievedTenInteractions) = fanEngagement.getUserStats(FAN);
        assertTrue(hasAchievedTenInteractions);
        vm.stopPrank();
    }
}
