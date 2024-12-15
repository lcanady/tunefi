// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RoyaltyDistributor.sol";
import "../src/TuneToken.sol";
import "../src/MusicNFT.sol";

contract RoyaltyDistributorTest is Test {
    RoyaltyDistributor public distributor;
    TuneToken public token;
    MusicNFT public nft;

    address public admin = address(1);
    address public artist = address(2);
    address public producer = address(3);
    address public collaborator = address(4);
    address public platform = address(5);

    uint256 public constant INITIAL_BALANCE = 1000 * 10**18;
    uint256 public constant MIN_DISTRIBUTION_THRESHOLD = 10 * 10**18;
    uint256 public constant TOTAL_SUPPLY = 1000000 * 10**18;
    uint256 public tokenId;

    event RoyaltyDistributed(uint256 indexed tokenId, uint256 amount);
    event PayeeAdded(uint256 indexed tokenId, address indexed account, uint256 shares);
    event PayeeRemoved(uint256 indexed tokenId, address indexed account);
    event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy contracts
        token = new TuneToken(TOTAL_SUPPLY);
        nft = new MusicNFT();
        distributor = new RoyaltyDistributor(address(token));
        
        // Setup initial token balances
        token.transfer(address(distributor), INITIAL_BALANCE * 5);
        token.transfer(address(this), INITIAL_BALANCE * 5);
        token.approve(address(distributor), type(uint256).max);
        
        // Setup NFT for testing
        tokenId = 1;
        address[] memory artists = new address[](1);
        uint256[] memory shares = new uint256[](1);
        artists[0] = artist;
        shares[0] = 10000; // 100% in basis points
        
        vm.mockCall(
            address(nft),
            abi.encodeWithSelector(nft.createTrackWithCollaborators.selector, "ipfs://test/", artists, shares, 1, 0),
            abi.encode(tokenId)
        );
        nft.createTrackWithCollaborators("ipfs://test/", artists, shares, 1, 0);
        
        // Setup royalty shares for tokenId
        address[] memory payees = new address[](4);
        uint256[] memory royaltyShares = new uint256[](4);
        
        payees[0] = artist;      royaltyShares[0] = 50; // 50%
        payees[1] = producer;    royaltyShares[1] = 25; // 25%
        payees[2] = collaborator;royaltyShares[2] = 15; // 15%
        payees[3] = platform;    royaltyShares[3] = 10; // 10%
        
        distributor.setPayees(tokenId, payees, royaltyShares);
        distributor.setDistributionThreshold(MIN_DISTRIBUTION_THRESHOLD);
        
        vm.stopPrank();
    }

    function test_SetPayees() public {
        address[] memory payees = new address[](2);
        uint256[] memory shares = new uint256[](2);
        payees[0] = artist;
        payees[1] = producer;
        shares[0] = 70;
        shares[1] = 30;

        vm.prank(admin);
        distributor.setPayees(2, payees, shares);

        (address retrievedPayee, uint256 retrievedShares) = distributor.payeeInfo(2, 0);
        assertEq(retrievedPayee, artist);
        assertEq(retrievedShares, 70);
    }

    function testFail_SetPayeesInvalidShares() public {
        address[] memory payees = new address[](2);
        uint256[] memory shares = new uint256[](2);
        payees[0] = artist;
        payees[1] = producer;
        shares[0] = 70;
        shares[1] = 40; // Total > 100

        vm.prank(admin);
        distributor.setPayees(2, payees, shares);
    }

    function test_DistributeRoyalties() public {
        uint256 amount = 100 * 10**18;
        uint256[] memory initialBalances = new uint256[](4);
        address[] memory payees = new address[](4);
        payees[0] = artist;
        payees[1] = producer;
        payees[2] = collaborator;
        payees[3] = platform;

        // Record initial balances
        for(uint i = 0; i < payees.length; i++) {
            initialBalances[i] = token.balanceOf(payees[i]);
        }

        // Distribute royalties
        vm.prank(admin);
        distributor.distributeRoyalties(tokenId, amount);

        // Verify balances
        assertEq(token.balanceOf(artist), initialBalances[0] + (amount * 50 / 100));
        assertEq(token.balanceOf(producer), initialBalances[1] + (amount * 25 / 100));
        assertEq(token.balanceOf(collaborator), initialBalances[2] + (amount * 15 / 100));
        assertEq(token.balanceOf(platform), initialBalances[3] + (amount * 10 / 100));
    }

    function testFail_DistributeBelowThreshold() public {
        uint256 amount = MIN_DISTRIBUTION_THRESHOLD - 1;
        
        vm.prank(admin);
        distributor.distributeRoyalties(tokenId, amount);
    }

    function test_UpdateThreshold() public {
        uint256 newThreshold = 20 * 10**18;
        
        vm.prank(admin);
        distributor.setDistributionThreshold(newThreshold);
        
        assertEq(distributor.distributionThreshold(), newThreshold);
    }

    function testFail_UnauthorizedThresholdUpdate() public {
        uint256 newThreshold = 20 * 10**18;
        
        vm.prank(artist);
        distributor.setDistributionThreshold(newThreshold);
    }

    function test_RemovePayee() public {
        vm.prank(admin);
        distributor.removePayee(tokenId, collaborator);
        
        // Verify collaborator was removed and shares redistributed
        uint256 totalShares;
        for(uint i = 0; i < distributor.getPayeeCount(tokenId); i++) {
            (,uint256 shares) = distributor.payeeInfo(tokenId, i);
            totalShares += shares;
        }
        
        assertEq(totalShares, 100);
        vm.expectRevert("Payee not found");
        distributor.getPayeeShares(tokenId, collaborator);
    }

    function test_BatchDistribution() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = 2;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 * 10**18;
        amounts[1] = 50 * 10**18;

        address[] memory payees = new address[](4);
        uint256[] memory shares = new uint256[](4);
        payees[0] = artist;      shares[0] = 50; // 50%
        payees[1] = producer;    shares[1] = 25; // 25%
        payees[2] = collaborator;shares[2] = 15; // 15%
        payees[3] = platform;    shares[3] = 10; // 10%

        address[] memory artists = new address[](1);
        uint256[] memory artistShares = new uint256[](1);
        artists[0] = artist;
        artistShares[0] = 10000; // 100% in basis points

        vm.startPrank(admin);
        vm.mockCall(
            address(nft),
            abi.encodeWithSelector(nft.createTrackWithCollaborators.selector, "ipfs://test/", artists, artistShares, 1, 0),
            abi.encode(tokenId)
        );
        nft.createTrackWithCollaborators("ipfs://test/", artists, artistShares, 1, 0);
        distributor.setPayees(2, payees, shares);
        distributor.batchDistributeRoyalties(tokenIds, amounts);
        vm.stopPrank();

        // Verify distributions
        assertEq(token.balanceOf(artist), (amounts[0] * 50 / 100) + (amounts[1] * 50 / 100));
        assertEq(token.balanceOf(producer), (amounts[0] * 25 / 100) + (amounts[1] * 25 / 100));
        assertEq(token.balanceOf(collaborator), (amounts[0] * 15 / 100) + (amounts[1] * 15 / 100));
        assertEq(token.balanceOf(platform), (amounts[0] * 10 / 100) + (amounts[1] * 10 / 100));
    }

    function test_AutomaticDistribution() public {
        uint256 amount = 100 * 10**18;
        
        // Setup automatic distribution threshold
        vm.prank(admin);
        distributor.setAutoDistributionThreshold(tokenId, 50 * 10**18);
        
        // Accumulate royalties
        vm.startPrank(admin);
        distributor.accumulateRoyalties(tokenId, amount);
        
        // Verify automatic distribution occurred
        assertEq(token.balanceOf(artist), amount * 50 / 100);
        assertEq(token.balanceOf(producer), amount * 25 / 100);
        assertEq(token.balanceOf(collaborator), amount * 15 / 100);
        assertEq(token.balanceOf(platform), amount * 10 / 100);
        vm.stopPrank();
    }

    function test_RoyaltyReconciliation() public {
        uint256 amount = 100 * 10**18;
        uint256 adjustmentAmount = 10 * 10**18;
        
        // Initial distribution
        vm.prank(admin);
        distributor.distributeRoyalties(tokenId, amount);
        
        // Record balances after initial distribution
        uint256 artistInitialBalance = token.balanceOf(artist);
        
        // Reconcile with adjustment
        vm.prank(admin);
        distributor.reconcileRoyalties(tokenId, adjustmentAmount, true); // true for positive adjustment
        
        // Verify adjustment was applied correctly
        assertEq(token.balanceOf(artist), artistInitialBalance + (adjustmentAmount * 50 / 100));
    }

    function test_StreamingRoyalties() public {
        uint256 ratePerMinute = 1 * 10**18; // 1 token per minute
        uint256 streamedMinutes = 30;
        
        vm.startPrank(admin);
        distributor.setStreamingRate(tokenId, ratePerMinute);
        
        // Check streaming rate was set correctly
        (uint256 rate,, ) = distributor.getStreamingStats(tokenId);
        assertEq(rate, ratePerMinute, "Incorrect streaming rate");
        
        // Record streaming minutes
        distributor.recordStreamingMinutes(tokenId, streamedMinutes);
        
        // Check streaming stats
        uint256 totalMinutes;
        uint256 accumulated;
        (rate, totalMinutes, accumulated) = distributor.getStreamingStats(tokenId);
        assertEq(totalMinutes, streamedMinutes, "Incorrect streaming minutes");
        assertEq(accumulated, streamedMinutes * ratePerMinute, "Incorrect accumulated royalties");
        
        // Distribute accumulated royalties
        distributor.distributeRoyalties(tokenId, accumulated);
        
        // Check balances after distribution
        assertEq(token.balanceOf(artist), (accumulated * 50) / 100, "Incorrect artist balance");
        assertEq(token.balanceOf(producer), (accumulated * 25) / 100, "Incorrect producer balance");
        assertEq(token.balanceOf(collaborator), (accumulated * 15) / 100, "Incorrect collaborator balance");
        assertEq(token.balanceOf(platform), (accumulated * 10) / 100, "Incorrect platform balance");
        
        vm.stopPrank();
    }

    function test_BatchStreamingMinutes() public {
        uint256[] memory tokenIds = new uint256[](2);
        tokenIds[0] = tokenId;
        tokenIds[1] = 2;

        uint256[] memory streamedMinutes = new uint256[](2);
        streamedMinutes[0] = 30;
        streamedMinutes[1] = 45;

        address[] memory artists = new address[](1);
        uint256[] memory artistShares = new uint256[](1);
        artists[0] = artist;
        artistShares[0] = 10000; // 100% in basis points

        vm.startPrank(admin);
        
        // Setup second token
        vm.mockCall(
            address(nft),
            abi.encodeWithSelector(nft.createTrackWithCollaborators.selector, "ipfs://test/", artists, artistShares, 1, 0),
            abi.encode(2)
        );
        nft.createTrackWithCollaborators("ipfs://test/", artists, artistShares, 1, 0);
        
        // Setup payees for second token
        address[] memory payees = new address[](4);
        uint256[] memory shares = new uint256[](4);
        payees[0] = artist;      shares[0] = 50;
        payees[1] = producer;    shares[1] = 25;
        payees[2] = collaborator;shares[2] = 15;
        payees[3] = platform;    shares[3] = 10;
        distributor.setPayees(2, payees, shares);
        
        // Set streaming rates
        uint256 ratePerMinute = 1 * 10**18;
        distributor.setStreamingRate(tokenId, ratePerMinute);
        distributor.setStreamingRate(2, ratePerMinute);
        
        // Record batch streaming minutes
        distributor.batchRecordStreamingMinutes(tokenIds, streamedMinutes);
        
        // Check streaming stats for both tokens
        uint256 minutes1;
        uint256 minutes2;
        uint256 accumulated1;
        uint256 accumulated2;
        (, minutes1, accumulated1) = distributor.getStreamingStats(tokenId);
        (, minutes2, accumulated2) = distributor.getStreamingStats(2);
        
        assertEq(minutes1, 30, "Incorrect minutes for token 1");
        assertEq(minutes2, 45, "Incorrect minutes for token 2");
        assertEq(accumulated1, 30 * ratePerMinute, "Incorrect accumulated royalties for token 1");
        assertEq(accumulated2, 45 * ratePerMinute, "Incorrect accumulated royalties for token 2");
        
        vm.stopPrank();
    }

    function testFail_RecordStreamingMinutesNoRate() public {
        vm.startPrank(admin);
        distributor.recordStreamingMinutes(tokenId, 30);
        vm.stopPrank();
    }

    function testFail_UnauthorizedStreamingRate() public {
        distributor.setStreamingRate(tokenId, 1 * 10**18);
    }
}
