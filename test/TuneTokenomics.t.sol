// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TuneToken.sol";

/// @title TuneTokenomics Test
/// @notice Test suite for TuneToken tokenomics features
/// @dev Tests inflation, staking, service tiers, and failure cases
contract TuneTokenomicsTest is Test {
    TuneToken public token;

    // Test addresses
    address public admin = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);

    // Constants for testing
    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1B tokens
    uint256 constant MAX_SUPPLY = 2_000_000_000 * 10 ** 18; // 2B tokens
    uint256 constant YEAR = 365 days;

    /// @notice Sets up the test environment
    /// @dev Deploys TuneToken contract and assigns admin role
    function setUp() public {
        vm.startPrank(admin);
        token = new TuneToken();
        vm.stopPrank();
    }

    // Supply Management Tests

    /// @notice Tests initial token supply and max supply constants
    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.MAX_SUPPLY(), MAX_SUPPLY);
    }

    /// @notice Tests the inflation mechanism and pool distribution
    /// @dev Verifies correct inflation rate and pool allocations
    function test_Inflation() public {
        // Move forward one year
        vm.warp(block.timestamp + YEAR);

        uint256 initialSupply = token.totalSupply();
        token.mintInflation();

        // Expected inflation is 2% of total supply
        uint256 expectedInflation = (initialSupply * token.INFLATION_RATE()) / 10000;
        assertEq(token.totalSupply(), initialSupply + expectedInflation);

        // Verify pool distributions
        assertEq(token.communityRewardsPool(), expectedInflation * 40 / 100); // 40%
        assertEq(token.ecosystemDevelopmentPool(), expectedInflation * 30 / 100); // 30%
        assertEq(token.liquidityMiningPool(), expectedInflation * 20 / 100); // 20%
        assertEq(token.governancePool(), expectedInflation * 10 / 100); // 10%
    }

    /// @notice Tests the maximum supply limit enforcement
    /// @dev Simulates multiple years of inflation to verify max supply cap
    function test_MaxSupplyLimit() public {
        vm.startPrank(admin);
        
        // Move forward multiple years to test max supply limit
        for (uint256 i = 0; i < 10; i++) {
            vm.warp(block.timestamp + YEAR);
            token.mintInflation();
            if (token.totalSupply() >= MAX_SUPPLY) break;
        }

        assertLe(token.totalSupply(), MAX_SUPPLY);
        vm.stopPrank();
    }

    /// @notice Tests token burning mechanism
    /// @dev Verifies burn tracking and supply reduction
    function test_Burning() public {
        uint256 burnAmount = 1000 * 10 ** 18;
        
        vm.startPrank(admin);
        token.transfer(user1, burnAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.burn(burnAmount);
        vm.stopPrank();

        assertEq(token.totalBurned(), burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    // Staking Tests

    /// @notice Tests basic staking functionality
    /// @dev Verifies stake amount and timestamp recording
    function test_Staking() public {
        uint256 stakeAmount = 1000 * 10 ** 18;
        
        vm.startPrank(admin);
        token.transfer(user1, stakeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        vm.stopPrank();

        (uint256 amount, uint256 startTime,) = token.stakes(user1);
        assertEq(amount, stakeAmount);
        assertEq(startTime, block.timestamp);
    }

    /// @notice Tests staking rewards distribution
    /// @dev Verifies equal reward distribution for equal stakes
    function test_StakingRewards() public {
        uint256 stakeAmount = 10000 * 10 ** 18;
        
        // Setup initial state
        vm.startPrank(admin);
        token.transfer(user1, stakeAmount);
        token.transfer(user2, stakeAmount);
        vm.stopPrank();

        // User1 and User2 stake tokens
        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        vm.stopPrank();

        // Move forward one epoch and distribute rewards
        vm.warp(block.timestamp + token.EPOCH_DURATION());
        token.advanceEpoch();

        // Users claim rewards
        vm.prank(user1);
        token.claimRewards();
        vm.prank(user2);
        token.claimRewards();

        // Verify equal reward distribution
        assertEq(token.balanceOf(user1), token.balanceOf(user2));
    }

    /// @notice Tests token unstaking functionality
    /// @dev Verifies partial unstaking and remaining stake calculation
    function test_Unstaking() public {
        uint256 stakeAmount = 1000 * 10 ** 18;
        
        vm.startPrank(admin);
        token.transfer(user1, stakeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);

        // Move forward some time
        vm.warp(block.timestamp + 30 days);

        uint256 unstakeAmount = stakeAmount / 2;
        token.unstake(unstakeAmount);
        vm.stopPrank();

        (uint256 remainingStake,,) = token.stakes(user1);
        assertEq(remainingStake, stakeAmount - unstakeAmount);
    }

    // Service Tier Tests

    /// @notice Tests service tier discount calculations
    /// @dev Verifies correct discount rates for different token holdings
    function test_ServiceTierDiscounts() public {
        // Test tier 1 (5% discount)
        uint256 tier1Amount = 10_000 * 10 ** 18;
        vm.startPrank(admin);
        token.transfer(user1, tier1Amount);
        vm.stopPrank();
        assertEq(token.getServiceTierDiscount(user1), 500); // 5%

        // Test tier 2 (10% discount)
        uint256 tier2Amount = 50_000 * 10 ** 18;
        vm.startPrank(admin);
        token.transfer(user2, tier2Amount);
        vm.stopPrank();
        assertEq(token.getServiceTierDiscount(user2), 1000); // 10%

        // Test tier 3 (20% discount)
        uint256 tier3Amount = 100_000 * 10 ** 18;
        vm.startPrank(admin);
        token.transfer(user3, tier3Amount);
        vm.stopPrank();
        assertEq(token.getServiceTierDiscount(user3), 2000); // 20%
    }

    // Failure Tests

    /// @notice Tests failure when staking below minimum amount
    /// @dev Should revert when stake amount is too low
    function testFail_StakeBelowMinimum() public {
        uint256 smallAmount = 100 * 10 ** 18; // Below minimum stake amount
        
        vm.startPrank(admin);
        token.transfer(user1, smallAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.stake(smallAmount);
        vm.stopPrank();
    }

    /// @notice Tests failure when unstaking more than staked amount
    /// @dev Should revert when unstake amount exceeds stake
    function testFail_UnstakeMoreThanStaked() public {
        uint256 stakeAmount = 1000 * 10 ** 18;
        
        vm.startPrank(admin);
        token.transfer(user1, stakeAmount);
        vm.stopPrank();

        vm.startPrank(user1);
        token.approve(address(token), stakeAmount);
        token.stake(stakeAmount);
        token.unstake(stakeAmount + 1);
        vm.stopPrank();
    }

    /// @notice Tests failure when attempting early inflation
    /// @dev Should revert when trying to mint inflation before time
    function testFail_EarlyInflation() public {
        token.mintInflation();
        token.mintInflation(); // Should fail as 1 year hasn't passed
    }

    /// @notice Tests failure when attempting early epoch advance
    /// @dev Should revert when trying to advance epoch too soon
    function testFail_EarlyEpochAdvance() public {
        token.advanceEpoch();
        token.advanceEpoch(); // Should fail as epoch duration hasn't passed
    }
} 