// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

contract BaseTest is Test {
    // Common addresses used across tests
    address internal constant ADMIN = address(0x1);
    address internal constant ARTIST = address(0x2);
    address internal constant FAN = address(0x3);
    address internal constant TREASURY = address(0x4);

    // Events for tracking test progress
    event TestStarted(string name);
    event TestCompleted(string name);

    function setUp() public virtual {
        // Label addresses for better trace output
        vm.label(ADMIN, "ADMIN");
        vm.label(ARTIST, "ARTIST");
        vm.label(FAN, "FAN");
        vm.label(TREASURY, "TREASURY");
    }

    // Helper to deal ETH to an address
    function dealETH(address to, uint256 amount) internal {
        vm.deal(to, amount);
    }

    // Helper to create a new address with ETH
    function createUser(string memory label, uint256 ethAmount) internal returns (address payable) {
        address payable user = payable(makeAddr(label));
        dealETH(user, ethAmount);
        return user;
    }

    // Helper for time manipulation
    function timeTravel(uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
        vm.roll(block.number + (seconds_ / 12)); // Assuming ~12 second block times
    }
} 