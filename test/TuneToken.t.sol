// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./Base.t.sol";
import "../src/TuneToken.sol";

contract TuneTokenTest is BaseTest {
    TuneToken public token;
    
    // Test data
    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;
    uint256 constant VESTING_AMOUNT = 100_000 ether;
    uint256 constant VESTING_DURATION = 365 days;
    
    function setUp() public override {
        super.setUp();
        
        // Deploy token contract
        vm.startPrank(ADMIN);
        token = new TuneToken(INITIAL_SUPPLY);
        vm.stopPrank();
    }

    // ERC20 Compliance Tests
    function test_InitialState() public {
        assertEq(token.name(), "TuneToken");
        assertEq(token.symbol(), "TUNE");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(ADMIN), INITIAL_SUPPLY);
        assertEq(token.owner(), ADMIN);
    }

    function test_Transfer() public {
        vm.startPrank(ADMIN);
        token.transfer(ARTIST, 1000 ether);
        assertEq(token.balanceOf(ARTIST), 1000 ether);
        assertEq(token.balanceOf(ADMIN), INITIAL_SUPPLY - 1000 ether);
        vm.stopPrank();
    }

    function test_TransferFrom() public {
        vm.startPrank(ADMIN);
        token.approve(ARTIST, 1000 ether);
        vm.stopPrank();

        vm.startPrank(ARTIST);
        token.transferFrom(ADMIN, FAN, 500 ether);
        assertEq(token.balanceOf(FAN), 500 ether);
        assertEq(token.balanceOf(ADMIN), INITIAL_SUPPLY - 500 ether);
        assertEq(token.allowance(ADMIN, ARTIST), 500 ether);
        vm.stopPrank();
    }

    // Vesting Tests
    function test_CreateVestingSchedule() public {
        uint256 startTime = block.timestamp + 1 days;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );

        (
            uint256 totalAmount,
            uint256 scheduleStartTime,
            uint256 duration,
            uint256 releasedAmount,
            bool revocable,
            bool revoked
        ) = token.vestingSchedules(ARTIST);

        assertEq(totalAmount, VESTING_AMOUNT);
        assertEq(scheduleStartTime, startTime);
        assertEq(duration, VESTING_DURATION);
        assertEq(releasedAmount, 0);
        assertTrue(revocable);
        assertFalse(revoked);
        vm.stopPrank();
    }

    function test_VestedAmount() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );
        vm.stopPrank();

        // Test at different time points
        vm.warp(startTime + VESTING_DURATION / 4);  // 25%
        uint256 expectedQuarter = VESTING_AMOUNT / 4;
        uint256 actualQuarter = token.vestedAmount(ARTIST);
        assertTrue(actualQuarter >= expectedQuarter - 1 && actualQuarter <= expectedQuarter + 1);

        vm.warp(startTime + VESTING_DURATION / 2);  // 50%
        uint256 expectedHalf = VESTING_AMOUNT / 2;
        uint256 actualHalf = token.vestedAmount(ARTIST);
        assertTrue(actualHalf >= expectedHalf - 1 && actualHalf <= expectedHalf + 1);

        vm.warp(startTime + VESTING_DURATION);  // 100%
        assertEq(token.vestedAmount(ARTIST), VESTING_AMOUNT);
    }

    function test_ReleaseVestedTokens() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );
        vm.stopPrank();

        // Move to 50% vesting point
        vm.warp(startTime + VESTING_DURATION / 2);
        
        vm.startPrank(ARTIST);
        token.releaseVestedTokens();
        uint256 expectedHalf = VESTING_AMOUNT / 2;
        uint256 actualBalance = token.balanceOf(ARTIST);
        assertTrue(actualBalance >= expectedHalf - 1 && actualBalance <= expectedHalf + 1);
        vm.stopPrank();
    }

    function test_RevokeVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );

        // Move to 25% vesting point and revoke
        vm.warp(startTime + VESTING_DURATION / 4);
        token.revokeVesting(ARTIST);

        // Check that ~25% is vested and the rest is returned to admin
        uint256 expectedVested = VESTING_AMOUNT / 4;
        uint256 actualVested = token.vestedAmount(ARTIST);
        assertTrue(actualVested >= expectedVested - 1 && actualVested <= expectedVested + 1);
        
        // Artist should be able to claim vested amount
        vm.stopPrank();

        vm.startPrank(ARTIST);
        token.releaseVestedTokens();
        uint256 actualBalance = token.balanceOf(ARTIST);
        assertTrue(actualBalance >= expectedVested - 1 && actualBalance <= expectedVested + 1);
        vm.stopPrank();
    }

    // Error Cases
    function testFail_CreateDuplicateVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );

        // Try to create another schedule for the same beneficiary
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );
        vm.stopPrank();
    }

    function testFail_RevokeNonRevocableVesting() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            false  // non-revocable
        );

        token.revokeVesting(ARTIST);
        vm.stopPrank();
    }

    function testFail_UnauthorizedRevoke() public {
        uint256 startTime = block.timestamp;
        
        vm.startPrank(ADMIN);
        token.createVestingSchedule(
            ARTIST,
            VESTING_AMOUNT,
            startTime,
            VESTING_DURATION,
            true
        );
        vm.stopPrank();

        vm.startPrank(ARTIST);
        token.revokeVesting(ARTIST);
        vm.stopPrank();
    }
}
