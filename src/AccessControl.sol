// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AccessControl
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. Roles are referred to by their bytes32 identifier.
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 */
contract AccessControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    // Events
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev The `DEFAULT_ADMIN_ROLE` is the role that serves as its own admin,
     * and should be granted with extreme caution.
     */
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     * Requirements:
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(
            hasRole(getRoleAdmin(role), msg.sender),
            "AccessControl: sender must be an admin to grant"
        );
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     * Requirements:
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(
            hasRole(getRoleAdmin(role), msg.sender),
            "AccessControl: sender must be an admin to revoke"
        );
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     */
    function renounceRole(bytes32 role) public virtual {
        require(hasRole(role, msg.sender), "AccessControl: can only renounce roles for self");
        _revokeRole(role, msg.sender);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     * Requirements:
     * - the caller must have `DEFAULT_ADMIN_ROLE`.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "AccessControl: must have default admin role to set role admin"
        );
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Returns true if the role's admin is the specified role
     */
    function isRoleAdmin(bytes32 role, bytes32 adminRole) public view returns (bool) {
        return getRoleAdmin(role) == adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     * Internal function without access restriction.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) private {
        _roles[role].adminRole = adminRole;
    }
}
