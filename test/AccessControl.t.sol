// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AccessControl.sol";

contract AccessControlTest is Test {
    AccessControl public access;
    
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
        access = new AccessControl();
        
        // Setup role hierarchy
        access.setRoleAdmin(ADMIN_ROLE, access.DEFAULT_ADMIN_ROLE());
        access.setRoleAdmin(MODERATOR_ROLE, ADMIN_ROLE);
        access.setRoleAdmin(ARTIST_ROLE, MODERATOR_ROLE);
        
        // Grant initial roles
        access.grantRole(ADMIN_ROLE, admin);
        vm.stopPrank();
    }
    
    function test_InitialState() public {
        assertTrue(access.hasRole(ADMIN_ROLE, admin));
        assertTrue(access.hasRole(access.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(access.isRoleAdmin(ADMIN_ROLE, access.DEFAULT_ADMIN_ROLE()));
        assertTrue(access.isRoleAdmin(MODERATOR_ROLE, ADMIN_ROLE));
        assertTrue(access.isRoleAdmin(ARTIST_ROLE, MODERATOR_ROLE));
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
        // First grant the role
        vm.prank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        assertTrue(access.hasRole(MODERATOR_ROLE, moderator));
        
        // Then revoke it
        vm.prank(admin);
        access.revokeRole(MODERATOR_ROLE, moderator);
        assertFalse(access.hasRole(MODERATOR_ROLE, moderator));
    }
    
    function test_RoleHierarchy() public {
        // Admin grants moderator role
        vm.prank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        
        // Moderator grants artist role
        vm.prank(moderator);
        access.grantRole(ARTIST_ROLE, artist);
        
        assertTrue(access.hasRole(ARTIST_ROLE, artist));
    }
    
    function testFail_RoleHierarchyViolation() public {
        // Artist tries to grant moderator role (should fail)
        vm.startPrank(artist);
        access.grantRole(MODERATOR_ROLE, user);
        vm.stopPrank();
    }
    
    function test_RenounceRole() public {
        // First grant the role
        vm.prank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        assertTrue(access.hasRole(MODERATOR_ROLE, moderator));
        
        // Moderator renounces their role
        vm.prank(moderator);
        access.renounceRole(MODERATOR_ROLE);
        assertFalse(access.hasRole(MODERATOR_ROLE, moderator));
    }
    
    function testFail_RenounceRoleForOthers() public {
        // First grant the role
        vm.prank(admin);
        access.grantRole(MODERATOR_ROLE, moderator);
        
        // Admin tries to make moderator renounce (should fail)
        vm.prank(admin);
        access.renounceRole(MODERATOR_ROLE);
    }
    
    function test_GetRoleAdmin() public {
        assertEq(access.getRoleAdmin(MODERATOR_ROLE), ADMIN_ROLE);
        assertEq(access.getRoleAdmin(ARTIST_ROLE), MODERATOR_ROLE);
    }
    
    function test_UpdateRoleAdmin() public {
        // Change artist role admin from moderator to admin
        vm.prank(admin);
        access.setRoleAdmin(ARTIST_ROLE, ADMIN_ROLE);
        
        assertEq(access.getRoleAdmin(ARTIST_ROLE), ADMIN_ROLE);
    }
    
    function testFail_UpdateRoleAdminUnauthorized() public {
        vm.prank(moderator);
        access.setRoleAdmin(ARTIST_ROLE, MODERATOR_ROLE);
    }
}
