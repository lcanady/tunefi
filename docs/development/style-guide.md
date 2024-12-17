# Style Guide

## Overview
This document outlines the coding standards and style guidelines for the TuneFi project, ensuring consistency and maintainability across the codebase.

## Code Organization

### 1. File Structure
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ICustom.sol";

// Contract
contract ContractName {
    // State variables
    // Events
    // Modifiers
    // Functions
}
```

### 2. Contract Layout
```solidity
contract ContractName {
    // Type declarations
    struct DataStruct {
        uint256 field1;
        address field2;
    }

    // State variables
    uint256 public stateVar;
    mapping(address => uint256) private balances;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // Functions by visibility/type
    constructor() { }
    receive() external payable { }
    fallback() external payable { }
    function publicFunction() public { }
    function externalFunction() external { }
    function internalFunction() internal { }
    function privateFunction() private { }
}
```

## Naming Conventions

### 1. Contract Names
```solidity
// Contracts use PascalCase
contract TuneToken { }
contract MusicNFT { }

// Interfaces prefix with I
interface ITuneToken { }
interface IMusicNFT { }

// Abstract contracts prefix with Base
abstract contract BaseTuneToken { }
```

### 2. Function Names
```solidity
// Functions use camelCase
function transferTokens() public { }
function mintNFT() external { }

// Internal/private functions prefix with _
function _validateInput() internal { }
function _processData() private { }
```

### 3. Variable Names
```solidity
// State variables use camelCase
uint256 public totalSupply;
address private owner;

// Constants use UPPER_CASE
uint256 public constant MAX_SUPPLY = 1000000;
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
```

## Documentation

### 1. NatSpec Comments
```solidity
/// @title Contract title
/// @author Author name
/// @notice Explain to a user what this does
/// @dev Explain to a developer any extra details
contract DocumentedContract {
    /// @notice Explain to a user what this function does
    /// @dev Explain to a developer any extra details
    /// @param user The address to check
    /// @return balance The user's balance
    function getBalance(address user)
        external
        view
        returns (uint256 balance)
    {
        return balances[user];
    }
}
```

### 2. Code Comments
```solidity
// Single-line comment for brief explanations
uint256 counter = 0; // Initialize counter

/*
 * Multi-line comment for more detailed explanations
 * that require multiple lines to properly document
 * the code's functionality
 */
function complexOperation() external {
    // Implementation
}
```

## Code Style

### 1. Indentation and Spacing
```solidity
contract StyleGuide {
    // Use 4 spaces for indentation
    function example(
        uint256 param1,
        address param2
    )
        external
        pure
        returns (bool)
    {
        // Function body
        if (param1 > 0) {
            return true;
        }
        return false;
    }
}
```

### 2. Function Ordering
```solidity
contract OrderedContract {
    // 1. Constructor
    constructor() { }

    // 2. Receive/Fallback
    receive() external payable { }
    fallback() external payable { }

    // 3. External functions
    function externalFunction() external { }

    // 4. Public functions
    function publicFunction() public { }

    // 5. Internal functions
    function _internalFunction() internal { }

    // 6. Private functions
    function _privateFunction() private { }
}
```

## Best Practices

### 1. Gas Optimization
```solidity
contract Optimized {
    // Pack variables
    struct PackedStruct {
        uint128 a; // Pack these two in one slot
        uint128 b;
    }

    // Use unchecked for safe math
    function increment(uint256 i) public pure returns (uint256) {
        unchecked { return i + 1; }
    }

    // Cache array length
    function processArray(uint256[] memory data) public pure {
        uint256 length = data.length;
        for (uint256 i = 0; i < length;) {
            // Process data
            unchecked { ++i; }
        }
    }
}
```

### 2. Security Patterns
```solidity
contract Secure {
    // Checks-Effects-Interactions pattern
    function transfer(address payable recipient, uint256 amount) external {
        // Checks
        require(amount <= balances[msg.sender], "Insufficient balance");
        
        // Effects
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        
        // Interactions
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Reentrancy guard
    modifier nonReentrant() {
        require(!locked, "Reentrant call");
        locked = true;
        _;
        locked = false;
    }
}
```

### 3. Error Handling
```solidity
contract ErrorHandling {
    // Use custom errors
    error InsufficientBalance(uint256 available, uint256 required);
    error Unauthorized(address caller);

    function withdraw(uint256 amount) external {
        if (amount > balances[msg.sender]) {
            revert InsufficientBalance({
                available: balances[msg.sender],
                required: amount
            });
        }
        // Process withdrawal
    }
}
```

## Testing Style

### 1. Test Organization
```solidity
contract ContractTest is Test {
    // Test setup
    function setUp() public {
        // Setup code
    }

    // Group tests by functionality
    function test_Deployment() public {
        // Deployment tests
    }

    function test_CoreFunctions() public {
        // Core function tests
    }

    function testFail_InvalidCases() public {
        // Failure cases
    }
}
```

### 2. Test Naming
```solidity
contract TestNaming is Test {
    // Standard test
    function test_FeatureName() public { }

    // Failure test
    function testFail_InvalidCondition() public { }

    // Fuzz test
    function testFuzz_FeatureWithInput(uint256 input) public { }

    // Fork test
    function testFork_NetworkSpecific() public { }
}
``` 