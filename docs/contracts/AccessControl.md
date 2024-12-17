# AccessControl Contract Documentation

## Overview
The AccessControl contract manages role-based permissions and access control across the TuneFi ecosystem. It implements a hierarchical role system with granular permissions and efficient role management.

## Features

### Role Management
- Hierarchical roles
- Role inheritance
- Custom role creation
- Role revocation
- Role renouncement

### Permission System
- Granular permissions
- Permission inheritance
- Scope-based access
- Time-based access
- Emergency controls

### Administrative Functions
- Role assignment
- Permission management
- Access verification
- Admin delegation
- Emergency controls

## Functions

### Role Management

#### grantRole
```solidity
function grantRole(
    bytes32 role,
    address account
) external onlyAdmin
```
Grants a role to an account.

#### revokeRole
```solidity
function revokeRole(
    bytes32 role,
    address account
) external onlyAdmin
```
Revokes a role from an account.

#### renounceRole
```solidity
function renounceRole(bytes32 role) external
```
Allows an account to renounce their role.

### Permission Management

#### setRolePermission
```solidity
function setRolePermission(
    bytes32 role,
    bytes32 permission,
    bool enabled
) external onlyAdmin
```
Sets permissions for a role.

#### checkPermission
```solidity
function checkPermission(
    address account,
    bytes32 permission
) external view returns (bool)
```
Checks if an account has a specific permission.

### Administrative Functions

#### createRole
```solidity
function createRole(
    string memory name,
    bytes32 parentRole
) external onlyAdmin returns (bytes32)
```
Creates a new role with optional inheritance.

#### setRoleAdmin
```solidity
function setRoleAdmin(
    bytes32 role,
    bytes32 adminRole
) external onlyAdmin
```
Sets the admin role for a role.

## Events

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
event RoleCreated(bytes32 indexed role, bytes32 indexed parentRole);
event PermissionSet(bytes32 indexed role, bytes32 indexed permission, bool enabled);
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed newAdminRole);
```

## Security Considerations

1. **Access Control**
   - Role validation
   - Permission checks
   - Admin verification
   - Emergency controls

2. **Role Security**
   - Inheritance validation
   - Permission scope
   - Role separation
   - Admin delegation

3. **Operational Security**
   - State consistency
   - Permission atomicity
   - Role lifecycle
   - Emergency procedures

## Integration Guide

### Granting Roles
```solidity
// Grant artist role
accessControl.grantRole(ARTIST_ROLE, artistAddress);
```

### Checking Permissions
```solidity
// Check if account can mint
bool canMint = accessControl.checkPermission(
    account,
    MINT_PERMISSION
);
```

### Creating Custom Roles
```solidity
// Create moderator role
bytes32 moderatorRole = accessControl.createRole(
    "MODERATOR",
    ADMIN_ROLE
);
```

## Testing

The contract includes comprehensive tests in `test/AccessControl.t.sol`:
- Role management
- Permission handling
- Admin functions
- Role inheritance
- Emergency procedures

## Deployment

Required parameters:
- Initial admin address
- Default roles
- Role hierarchy
- Permission mappings

## Gas Optimization

1. Efficient role storage
2. Permission caching
3. Minimal state changes
4. Optimized checks

## Audits

Focus areas:
1. Role management logic
2. Permission inheritance
3. Admin controls
4. Emergency procedures
5. State consistency

## Constants

### Default Roles
```solidity
bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 public constant ARTIST_ROLE = keccak256("ARTIST_ROLE");
bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
bytes32 public constant PLATFORM_ROLE = keccak256("PLATFORM_ROLE");
```

### Permissions
```solidity
bytes32 public constant MINT_PERMISSION = keccak256("MINT");
bytes32 public constant BURN_PERMISSION = keccak256("BURN");
bytes32 public constant UPDATE_PERMISSION = keccak256("UPDATE");
bytes32 public constant ADMIN_PERMISSION = keccak256("ADMIN");
```

## Role Hierarchy

```
DEFAULT_ADMIN_ROLE
├── PLATFORM_ROLE
│   ├── MODERATOR_ROLE
│   └── ARTIST_ROLE
└── EMERGENCY_ROLE
```

## Permission Matrix

| Role | Mint | Burn | Update | Admin |
|------|------|------|--------|-------|
| Admin | ✓ | ✓ | ✓ | ✓ |
| Platform | ✓ | ✓ | ✓ | - |
| Moderator | - | ✓ | ✓ | - |
| Artist | ✓ | - | ✓ | - |

## Emergency Procedures

1. **Role Revocation**
   - Immediate effect
   - Cascading revocation
   - Admin notification
   - State verification

2. **Permission Suspension**
   - Temporary disable
   - Scope limitation
   - Time constraints
   - Audit logging

3. **Admin Transfer**
   - Multi-sig requirement
   - Timelock delay
   - State verification
   - Backup procedures
