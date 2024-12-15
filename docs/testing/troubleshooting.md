# TuneFi Testing Troubleshooting Guide

## Common Issues and Solutions

### 1. Test Environment Setup

#### Issue: OpenZeppelin Contract Import Failures
```
Error: Cannot find contracts in @openzeppelin
```
**Solution:**
1. Install OpenZeppelin contracts:
```bash
forge install OpenZeppelin/openzeppelin-contracts
```
2. Verify remappings in `remappings.txt`:
```
@openzeppelin/=lib/openzeppelin-contracts/
```

#### Issue: Solidity Version Mismatch
```
Error: Source file requires different compiler version
```
**Solution:**
1. Check pragma statement in contracts
2. Update `foundry.toml` with correct version:
```toml
[profile.default]
solc_version = '0.8.20'
```

### 2. Test Execution Issues

#### Issue: Gas Estimation Failures
```
Error: gas required exceeds allowance
```
**Solution:**
1. Increase gas limit in `foundry.toml`:
```toml
[profile.default]
gas_limit = 9000000
```
2. Optimize contract code to reduce gas usage

#### Issue: Stack Too Deep
```
Error: Stack too deep
```
**Solution:**
1. Break down complex functions into smaller ones
2. Use structs to group related variables
3. Optimize local variable usage

### 3. Test Assertion Failures

#### Issue: Event Assertion Failures
```
Error: Event not emitted
```
**Solution:**
1. Verify event emission in contract
2. Check event parameter types match
3. Use correct assertion:
```solidity
vm.expectEmit(true, true, true, true);
emit ExpectedEvent(param1, param2);
```

#### Issue: Revert Message Mismatch
```
Error: Revert message mismatch
```
**Solution:**
1. Use exact error message or custom error
2. For custom errors:
```solidity
vm.expectRevert(abi.encodeWithSignature("CustomError(address)", param));
```

### 4. Coverage Issues

#### Issue: Uncovered Code Paths
**Solution:**
1. Add test cases for edge cases
2. Include failure scenarios
3. Test boundary conditions

#### Issue: Branch Coverage Gaps
**Solution:**
1. Add tests for each conditional branch
2. Include tests for all require/revert conditions
3. Test different parameter combinations

### 5. Performance Issues

#### Issue: Slow Test Execution
**Solution:**
1. Use `forge test --match-path` to run specific tests
2. Optimize setup/teardown operations
3. Use efficient test patterns

#### Issue: Memory Usage Problems
**Solution:**
1. Clean up test data after each test
2. Optimize array and mapping usage
3. Use appropriate data structures

## Best Practices

### 1. Test Organization
- Group related tests together
- Use clear, descriptive test names
- Follow consistent naming conventions
- Maintain test independence

### 2. Test Data Management
- Use fixtures for common test data
- Clean up test data after each test
- Use meaningful test values
- Avoid hardcoded values

### 3. Error Handling
- Test both success and failure cases
- Verify error messages
- Test access control
- Validate state changes

### 4. Gas Optimization
- Monitor gas usage trends
- Optimize expensive operations
- Use gas-efficient patterns
- Regular gas profiling

## Known Edge Cases

### 1. MusicNFT Contract
- Multiple artists with equal shares
- Zero-price tracks and albums
- Maximum supply limitations
- Complex royalty calculations

### 2. RecommendationGraph Contract
- Large number of track relationships
- Complex recommendation paths
- High user interaction volume
- Concurrent updates

### 3. TuneToken Contract
- Complex vesting schedules
- Multiple vesting beneficiaries
- Token transfer restrictions
- Vesting revocation scenarios
