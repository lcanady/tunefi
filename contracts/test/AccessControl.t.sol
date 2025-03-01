// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TuneAccessControl.sol";

contract AccessControlTest is Test {
    TuneAccessControl public access;

    address public admin = address(1);
    address public moderator = address(2);
    address public artist = address(3);
    address public user = address(4);

    // Role identifiers
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");

    function setUp() public {
        vm.startPrank(admin);
        access = new TuneAccessControl();

        // Grant roles
        access.grantRole(ADMIN_ROLE, admin);

        // Set up role admins
        access.setRoleAdmin(MODERATOR_ROLE, ADMIN_ROLE);
        access.setRoleAdmin(ARTIST_ROLE, MODERATOR_ROLE);

        vm.stopPrank();
    }

    function test_InitialState() public view {
        assertTrue(access.hasRole(ADMIN_ROLE, admin));
        assertTrue(access.hasRole(access.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(access.getRoleAdmin(MODERATOR_ROLE), ADMIN_ROLE);
        assertEq(access.getRoleAdmin(ARTIST_ROLE), MODERATOR_ROLE);
    }

    function test_GrantRole() public {
        vm.startPrank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        vm.stopPrank();

        assertTrue(access.hasRole(MODERATOR_ROLE, moderator));
    }

    function testFail_GrantRoleUnauthorized() public {
        vm.prank(user);
        access.grantRole(MODERATOR_ROLE, moderator);
    }

    function test_RevokeRole() public {
        vm.startPrank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        access.revokeRole(MODERATOR_ROLE, moderator);
        vm.stopPrank();

        assertFalse(access.hasRole(MODERATOR_ROLE, moderator));
    }

    function testFail_RevokeRoleUnauthorized() public {
        vm.startPrank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        vm.stopPrank();

        vm.prank(user);
        access.revokeRole(MODERATOR_ROLE, moderator);
    }

    function test_RoleHierarchy() public {
        vm.startPrank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        vm.stopPrank();

        vm.startPrank(moderator);
        access.grantRole(ARTIST_ROLE, artist);
        vm.stopPrank();

        assertTrue(access.hasRole(ARTIST_ROLE, artist));
    }

    function testFail_RoleHierarchyUnauthorized() public {
        vm.startPrank(artist);
        access.grantRole(MODERATOR_ROLE, moderator);
        vm.stopPrank();
    }
}
