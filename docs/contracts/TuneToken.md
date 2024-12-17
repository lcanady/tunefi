# TuneToken Contract Documentation

## Overview
TuneToken (TUNE) is the governance and utility token for the TuneFi ecosystem. It implements ERC20 with advanced tokenomics features including voting, vesting, staking, and inflation mechanics.

## Features

### Supply Management
- Initial Supply: 1 billion tokens
- Maximum Supply: 2 billion tokens
- Annual Inflation Rate: 2% (200 basis points)
- Maximum Inflation Rate: 5% (500 basis points)
- Burn Rate: 1% of platform fees (100 basis points)

### Distribution Pools
- Community Rewards Pool (40% of inflation)
- Ecosystem Development Pool (30% of inflation)
- Liquidity Mining Pool (20% of inflation)
- Governance Pool (10% of inflation)

### Staking System
- Minimum Stake: 1,000 TUNE
- Epoch Duration: 7 days
- Reward Distribution: Based on pro-rata share of staked tokens
- Staking Requirements: Token approval and minimum balance

### Service Tiers
1. Tier 1:
   - Requirement: 10,000 TUNE
   - Discount: 5% (500 basis points)
2. Tier 2:
   - Requirement: 50,000 TUNE
   - Discount: 10% (1,000 basis points)
3. Tier 3:
   - Requirement: 100,000 TUNE
   - Discount: 20% (2,000 basis points)

### Vesting System
- Customizable vesting schedules
- Optional revocability
- Linear vesting over time
- Early vesting termination support

## Functions

### Supply Management

#### mintInflation
```solidity
function mintInflation() external
```
Mints new tokens according to the annual inflation schedule. Can only be called once per year and respects the maximum supply cap.

#### burn
```solidity
function burn(uint256 amount) external
```
Burns tokens from the caller's balance and updates the total burned counter.

### Staking

#### stake
```solidity
function stake(uint256 amount) external
```
Stakes tokens for rewards. Requires minimum stake amount and sufficient balance.

#### unstake
```solidity
function unstake(uint256 amount) external
```
Unstakes tokens and updates rewards before processing.

#### claimRewards
```solidity
function claimRewards() external
```
Claims accumulated staking rewards after updating reward calculations.

#### advanceEpoch
```solidity
function advanceEpoch() external
```
Advances the epoch and updates reward rates from the liquidity mining pool.

### Service Tiers

#### getServiceTierDiscount
```solidity
function getServiceTierDiscount(address user) external view returns (uint256)
```
Returns the highest eligible discount rate for a user based on their token balance.

### Vesting

#### createVestingSchedule
```solidity
function createVestingSchedule(
    address beneficiary,
    uint256 amount,
    uint256 startTime,
    uint256 duration,
    bool revocable
) external onlyOwner
```
Creates a vesting schedule for a beneficiary with specified parameters.

#### revokeVesting
```solidity
function revokeVesting(address beneficiary) external onlyOwner
```
Revokes a revocable vesting schedule and returns unvested tokens.

#### releaseVestedTokens
```solidity
function releaseVestedTokens() external
```
Releases vested tokens for the caller.

## Events

```solidity
event VestingScheduleCreated(address indexed beneficiary, uint256 amount, uint256 startTime, uint256 duration);
event VestingScheduleRevoked(address indexed beneficiary);
event TokensReleased(address indexed beneficiary, uint256 amount);
event Staked(address indexed user, uint256 amount);
event Unstaked(address indexed user, uint256 amount);
event RewardPaid(address indexed user, uint256 reward);
event TokensBurned(address indexed from, uint256 amount);
event PoolFunded(string indexed poolName, uint256 amount);
event ServiceTierUpdated(uint256 indexed tier, uint256 minTokens, uint256 discountRate);
event EpochAdvanced(uint256 indexed epoch, uint256 rewardPerToken);
```

## Security Considerations

1. **Access Control**
   - Owner-only functions for critical operations
   - Role-based access for administrative functions
   - Timelock integration for governance actions

2. **Economic Security**
   - Maximum supply cap
   - Controlled inflation rate
   - Minimum stake requirements
   - Vesting schedules for large holders

3. **Operational Security**
   - Reentrancy protection
   - Safe math operations
   - Input validation
   - Event emission for tracking

## Integration Guide

### Staking Integration
```solidity
// Approve tokens first
tuneToken.approve(address(tuneToken), amount);

// Stake tokens
tuneToken.stake(amount);

// After epoch duration
tuneToken.advanceEpoch();

// Claim rewards
tuneToken.claimRewards();
```

### Vesting Integration
```solidity
// Create vesting schedule
tuneToken.createVestingSchedule(
    beneficiary,
    amount,
    startTime,
    duration,
    revocable
);

// Release vested tokens
tuneToken.releaseVestedTokens();
```

### Service Tier Integration
```solidity
// Get user's discount rate
uint256 discount = tuneToken.getServiceTierDiscount(userAddress);
```

## Testing

Comprehensive test coverage is provided in `test/TuneTokenomics.t.sol`, including:
- Supply management tests
- Staking functionality tests
- Service tier tests
- Vesting schedule tests
- Failure case tests

## Deployment

The contract requires the following parameters during deployment:
- No constructor parameters (uses default values)
- Initial supply of 1 billion tokens minted to deployer
- Service tiers initialized with default values

## Upgradeability

The contract is not upgradeable. Any changes would require:
1. Deploying a new contract
2. Migrating balances and state
3. Updating dependent contracts

## Gas Optimization

The contract implements several gas optimization techniques:
1. Efficient storage packing
2. Batch operations where possible
3. View functions for read-only operations
4. Minimal storage operations

## Audits

The contract should undergo security audits focusing on:
1. Tokenomics implementation
2. Staking mechanics
3. Vesting logic
4. Access control
5. Economic security
