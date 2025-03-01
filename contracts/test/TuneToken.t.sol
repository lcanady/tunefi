// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TuneToken.sol";

contract TuneTokenTest is Test {
    TuneToken public token;

    address public admin = address(1);
    address public artist = address(2);
    address public fan = address(3);

    uint256 constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1B tokens
    uint256 constant VESTING_AMOUNT = 1_000_000 * 10 ** 18; // 1M tokens
    uint256 constant VESTING_DURATION = 365 days;

    function setUp() public {
        vm.startPrank(admin);
        token = new TuneToken();
        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertEq(token.name(), "TuneToken");
        assertEq(token.symbol(), "TUNE");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY);
        assertEq(token.owner(), admin);
    }

    function test_Transfer() public {
        vm.startPrank(admin);
        token.transfer(artist, 1000 ether);
        assertEq(token.balanceOf(artist), 1000 ether);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - 1000 ether);
        vm.stopPrank();
    }

    function test_TransferFrom() public {
        vm.startPrank(admin);
        token.approve(artist, 1000 ether);
        vm.stopPrank();

        vm.startPrank(artist);
        token.transferFrom(admin, fan, 500 ether);
        assertEq(token.balanceOf(fan), 500 ether);
        assertEq(token.balanceOf(admin), INITIAL_SUPPLY - 500 ether);
        assertEq(token.allowance(admin, artist), 500 ether);
        vm.stopPrank();
    }

    function test_CreateVestingSchedule() public {
        uint256 startTime = block.timestamp + 1 days;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);

        (
            uint256 totalAmount,
            uint256 scheduleStartTime,
            uint256 duration,
            uint256 releasedAmount,
            bool revocable,
            bool revoked
        ) = token.vestingSchedules(artist);

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

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);

        // Test at different time points
        vm.warp(startTime + VESTING_DURATION / 4); // 25%
        uint256 expectedQuarter = VESTING_AMOUNT / 4;
        uint256 actualQuarter = token.vestedAmount(artist);
        assertTrue(actualQuarter >= expectedQuarter - 1 && actualQuarter <= expectedQuarter + 1);

        vm.warp(startTime + VESTING_DURATION / 2); // 50%
        uint256 expectedHalf = VESTING_AMOUNT / 2;
        uint256 actualHalf = token.vestedAmount(artist);
        assertTrue(actualHalf >= expectedHalf - 1 && actualHalf <= expectedHalf + 1);

        vm.warp(startTime + VESTING_DURATION); // 100%
        assertEq(token.vestedAmount(artist), VESTING_AMOUNT);
        vm.stopPrank();
    }

    function test_ReleaseVestedTokens() public {
        uint256 startTime = block.timestamp;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);

        // Move to 50% vesting point
        vm.warp(startTime + VESTING_DURATION / 2);
        vm.stopPrank();

        vm.startPrank(artist);
        token.releaseVestedTokens();
        uint256 expectedHalf = VESTING_AMOUNT / 2;
        uint256 actualBalance = token.balanceOf(artist);
        assertTrue(actualBalance >= expectedHalf - 1 && actualBalance <= expectedHalf + 1);
        vm.stopPrank();
    }

    function test_RevokeVesting() public {
        uint256 startTime = block.timestamp;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);

        // Move to 25% vesting point and revoke
        vm.warp(startTime + VESTING_DURATION / 4);
        token.revokeVesting(artist);

        // Check that ~25% is vested and the rest is returned to admin
        uint256 expectedVested = VESTING_AMOUNT / 4;
        uint256 actualVested = token.vestedAmount(artist);
        assertTrue(actualVested >= expectedVested - 1 && actualVested <= expectedVested + 1);
        vm.stopPrank();

        // Artist should be able to claim vested amount
        vm.startPrank(artist);
        token.releaseVestedTokens();
        uint256 actualBalance = token.balanceOf(artist);
        assertTrue(actualBalance >= expectedVested - 1 && actualBalance <= expectedVested + 1);
        vm.stopPrank();
    }

    function testFail_CreateDuplicateVesting() public {
        uint256 startTime = block.timestamp;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);

        // Try to create another schedule for the same beneficiary
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);
        vm.stopPrank();
    }

    function testFail_RevokeNonRevocableVesting() public {
        uint256 startTime = block.timestamp;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, false);

        token.revokeVesting(artist);
        vm.stopPrank();
    }

    function testFail_UnauthorizedRevoke() public {
        uint256 startTime = block.timestamp;

        vm.startPrank(admin);
        token.createVestingSchedule(artist, VESTING_AMOUNT, startTime, VESTING_DURATION, true);
        vm.stopPrank();

        vm.startPrank(artist);
        token.revokeVesting(artist);
        vm.stopPrank();
    }
}
