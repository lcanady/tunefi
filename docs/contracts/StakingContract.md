# StakingContract Documentation

## Overview
The StakingContract enables users to stake TUNE tokens to earn rewards and participate in governance. It implements a flexible staking mechanism with time-weighted rewards and governance power calculation.

## Features

### 1. Staking Mechanism
- Flexible stake duration
- Time-weighted rewards
- Lock period options
- Early withdrawal penalties

### 2. Rewards System
- Dynamic reward rates
- Compound interest calculation
- Bonus rewards for longer stakes
- Reward boost multipliers

### 3. Governance Integration
- Voting power calculation
- Time-weighted governance power
- Delegation capabilities
- Power boost for longer locks

## Contract Interface

### Constructor
```solidity
constructor(
    address _tuneToken,
    address _rewardsToken,
    uint256 _rewardRate
)
```
Initializes the staking contract with token addresses and reward rate.

### Staking Functions

#### Stake Tokens
```solidity
function stake(
    uint256 amount,
    uint256 lockDuration
) external
```
Stakes tokens with optional lock duration.

#### Withdraw Tokens
```solidity
function withdraw(uint256 amount) external
```
Withdraws staked tokens after lock period.

#### Claim Rewards
```solidity
function claimRewards() external returns (uint256)
```
Claims accumulated rewards.

### Governance Functions

#### Get Voting Power
```solidity
function getVotingPower(address account) external view returns (uint256)
```
Returns the current voting power of an account.

#### Delegate Voting Power
```solidity
function delegateVotingPower(address delegatee) external
```
Delegates voting power to another address.

## Events

### Staked
```solidity
event Staked(
    address indexed user,
    uint256 amount,
    uint256 lockDuration
)
```

### Withdrawn
```solidity
event Withdrawn(
    address indexed user,
    uint256 amount
)
```

### RewardsClaimed
```solidity
event RewardsClaimed(
    address indexed user,
    uint256 amount
)
```

### VotingPowerDelegated
```solidity
event VotingPowerDelegated(
    address indexed delegator,
    address indexed delegatee
)
```

## Data Structures

### Stake
```solidity
struct Stake {
    uint256 amount;
    uint256 startTime;
    uint256 endTime;
    uint256 lastUpdateTime;
    uint256 rewardDebt;
}
```

### UserInfo
```solidity
struct UserInfo {
    uint256 totalStaked;
    uint256 rewardsEarned;
    address delegatee;
    Stake[] stakes;
}
```

## Access Control
- Only token holders can stake
- Only stakers can withdraw
- Only stakers can claim rewards
- Anyone can delegate voting power

## Security Considerations

### 1. Staking Security
- Lock period enforcement
- Withdrawal validations
- Stake amount limits
- Slashing protection

### 2. Rewards Security
- Reward rate controls
- Overflow protection
- Reward pool management
- Double-claim prevention

### 3. Governance Security
- Delegation validation
- Power calculation accuracy
- Time manipulation protection

## Gas Optimization
- Efficient reward calculation
- Optimized storage layout
- Batch processing support
- Cache frequently used values

## Error Cases
```solidity
error InsufficientBalance()
error StakeLocked()
error NoRewardsAvailable()
error InvalidDelegation()
error InvalidWithdrawalAmount()
```

## Integration Examples

### Staking Tokens
```solidity
// Approve tokens first
tuneToken.approve(stakingContract, amount);

// Stake tokens for 1 year
uint256 lockDuration = 365 days;
stakingContract.stake(amount, lockDuration);
```

### Claiming Rewards
```solidity
// Claim accumulated rewards
uint256 rewards = stakingContract.claimRewards();
```

### Delegating Voting Power
```solidity
// Delegate voting power
stakingContract.delegateVotingPower(delegatee);
```

## Best Practices
1. Regular rewards distribution
2. Proper lock period management
3. Accurate voting power tracking
4. Safe withdrawal processing
5. Efficient reward calculations

## Upgrades and Maintenance
- Reward rate adjustments
- Lock period modifications
- Governance power calculations
- Emergency pause functionality

## Performance Considerations
1. Batch processing for multiple stakes
2. Optimized reward calculations
3. Efficient storage usage
4. Gas-efficient operations

## Testing Guidelines
1. Test all staking scenarios
2. Verify reward calculations
3. Validate governance power
4. Check delegation logic
5. Test emergency scenarios
