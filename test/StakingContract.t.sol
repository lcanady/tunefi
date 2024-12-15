// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StakingContract.sol";
import "../src/TuneToken.sol";

contract StakingContractTest is Test {
    StakingContract public staking;
    TuneToken public token;
    
    address public admin = address(1);
    address public alice = address(2);
    address public bob = address(3);
    address public carol = address(4);
    
    uint256 public constant MIN_STAKE = 100 * 10**18; // 100 tokens
    uint256 public constant REWARD_RATE = 10; // 10% annual
    uint256 public constant SLASH_RATE = 50; // 50% slash
    uint256 public constant INITIAL_BALANCE = 1000 * 10**18; // 1000 tokens
    uint256 public constant TOTAL_SUPPLY = 10000 * 10**18; // 10000 tokens for testing
    
    function setUp() public {
        vm.startPrank(admin);
        
        // Deploy token with initial supply
        token = new TuneToken(TOTAL_SUPPLY);
        
        // Deploy staking contract
        staking = new StakingContract(
            address(token),
            MIN_STAKE,
            REWARD_RATE,
            SLASH_RATE
        );
        
        // Transfer initial balances to test accounts
        token.transfer(alice, INITIAL_BALANCE);
        token.transfer(bob, INITIAL_BALANCE);
        token.transfer(carol, INITIAL_BALANCE);
        
        vm.stopPrank();
    }
    
    function test_StakingSetup() public {
        assertEq(address(staking.stakingToken()), address(token));
        assertEq(staking.minStakeAmount(), MIN_STAKE);
        assertEq(staking.rewardRate(), REWARD_RATE);
        assertEq(staking.slashRate(), SLASH_RATE);
    }
    
    function test_Stake() public {
        uint256 stakeAmount = MIN_STAKE;
        
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        (uint256 amount, uint256 lastRewardUpdate, uint256 rewardDebt, address delegatedTo) = staking.stakes(alice);
        assertEq(amount, stakeAmount);
        assertEq(staking.totalStaked(), stakeAmount);
        assertEq(token.balanceOf(address(staking)), stakeAmount);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE - stakeAmount);
    }
    
    function testFail_StakeBelowMinimum() public {
        uint256 stakeAmount = MIN_STAKE - 1;
        
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
    }
    
    function test_StakeMultiple() public {
        uint256 firstStake = MIN_STAKE;
        uint256 secondStake = MIN_STAKE * 2;
        
        vm.startPrank(alice);
        token.approve(address(staking), firstStake + secondStake);
        
        staking.stake(firstStake);
        (uint256 amount1,,, ) = staking.stakes(alice);
        assertEq(amount1, firstStake);
        
        staking.stake(secondStake);
        (uint256 amount2,,, ) = staking.stakes(alice);
        assertEq(amount2, firstStake + secondStake);
        vm.stopPrank();
    }
    
    function test_EmergencyState() public {
        vm.prank(admin);
        staking.setEmergencyState(true);
        
        uint256 stakeAmount = MIN_STAKE;
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        
        vm.expectRevert(bytes4(keccak256("EnforcedPause()")));
        staking.stake(stakeAmount);
        vm.stopPrank();
    }

    function test_RewardCalculation() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        // Move forward 1 year
        vm.warp(block.timestamp + 365 days);
        
        // Calculate expected rewards (10% annual rate)
        uint256 expectedReward = (stakeAmount * REWARD_RATE) / 100;
        
        // Check pending rewards
        uint256 pendingRewards = staking.pendingRewards(alice);
        assertEq(pendingRewards, expectedReward);
    }
    
    function test_ClaimRewards() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        
        // Move forward 1 year
        vm.warp(block.timestamp + 365 days);
        
        // Calculate expected rewards
        uint256 expectedReward = (stakeAmount * REWARD_RATE) / 100;
        uint256 initialBalance = token.balanceOf(alice);
        
        // Claim rewards
        staking.claimRewards();
        vm.stopPrank();
        
        // Verify rewards were received
        assertEq(token.balanceOf(alice), initialBalance + expectedReward);
        assertEq(staking.pendingRewards(alice), 0);
    }
    
    function test_Delegation() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        
        // Delegate to bob
        staking.delegate(bob);
        vm.stopPrank();
        
        // Check delegation state
        (,,, address delegatedTo) = staking.stakes(alice);
        assertEq(delegatedTo, bob);
        assertEq(staking.delegatedPower(bob), stakeAmount);
    }
    
    function test_Undelegate() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake and delegate
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        staking.delegate(bob);
        
        // Undelegate
        staking.undelegate();
        vm.stopPrank();
        
        // Check delegation was removed
        (,,, address delegatedTo) = staking.stakes(alice);
        assertEq(delegatedTo, address(0));
        assertEq(staking.delegatedPower(bob), 0);
    }
    
    function testFail_DelegateToSelf() public {
        uint256 stakeAmount = MIN_STAKE;
        
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        staking.delegate(alice);
        vm.stopPrank();
    }
    
    function test_Slashing() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        // Set bob as slasher
        vm.prank(admin);
        staking.setSlasher(bob, true);
        
        // Perform slash
        vm.prank(bob);
        staking.slash(alice);
        
        // Calculate expected remaining stake
        uint256 expectedRemaining = (stakeAmount * (100 - SLASH_RATE)) / 100;
        
        // Verify slash results
        (uint256 amount,,, ) = staking.stakes(alice);
        assertEq(amount, expectedRemaining);
        assertEq(staking.totalStaked(), expectedRemaining);
    }
    
    function testFail_UnauthorizedSlash() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        // Try to slash without authorization
        vm.prank(bob);
        staking.slash(alice);
    }
    
    function test_EmergencyWithdraw() public {
        uint256 stakeAmount = MIN_STAKE;
        
        // Stake tokens
        vm.startPrank(alice);
        token.approve(address(staking), stakeAmount);
        staking.stake(stakeAmount);
        vm.stopPrank();
        
        // Enable emergency state
        vm.prank(admin);
        staking.setEmergencyState(true);
        
        // Perform emergency withdrawal
        vm.startPrank(alice);
        staking.emergencyWithdraw();
        vm.stopPrank();
        
        // Verify withdrawal
        (uint256 amount,,, ) = staking.stakes(alice);
        assertEq(amount, 0);
        assertEq(token.balanceOf(alice), INITIAL_BALANCE);
        assertEq(staking.totalStaked(), 0);
    }
}
