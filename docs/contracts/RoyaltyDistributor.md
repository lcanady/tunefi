# RoyaltyDistributor Contract Documentation

## Overview
RoyaltyDistributor manages the distribution of royalties for music NFTs in the TuneFi ecosystem. It handles payment splitting, streaming royalties, and batch distributions with configurable thresholds.

## Features

### Payment Distribution
- Configurable distribution thresholds
- Batch payment processing
- Gas-optimized splitting
- Automatic fee handling

### Streaming Royalties
- Real-time royalty accrual
- Per-second rate calculation
- Automated distribution triggers
- Balance tracking per recipient

### Fee Management
- Platform fee calculation
- Fee recipient management
- Dynamic fee adjustment
- Fee distribution tracking

## Functions

### Distribution Management

#### distributeRoyalties
```solidity
function distributeRoyalties(
    uint256 tokenId,
    uint256 amount,
    address[] memory recipients,
    uint256[] memory shares
) external
```
Distributes royalties for a token sale to multiple recipients.

#### batchDistribute
```solidity
function batchDistribute(
    uint256[] memory tokenIds,
    uint256[] memory amounts,
    address[][] memory recipients,
    uint256[][] memory shares
) external
```
Processes multiple royalty distributions in a single transaction.

#### updateDistributionThreshold
```solidity
function updateDistributionThreshold(uint256 newThreshold) external onlyOwner
```
Updates the minimum amount required for distribution.

### Balance Management

#### withdrawBalance
```solidity
function withdrawBalance() external
```
Allows a recipient to withdraw their accumulated royalties.

#### getRecipientBalance
```solidity
function getRecipientBalance(address recipient) external view returns (uint256)
```
Returns the current balance of a royalty recipient.

### Fee Management

#### updatePlatformFee
```solidity
function updatePlatformFee(uint256 newFee) external onlyOwner
```
Updates the platform fee percentage.

#### withdrawPlatformFees
```solidity
function withdrawPlatformFees() external onlyOwner
```
Withdraws accumulated platform fees.

## Events

```solidity
event RoyaltyDistributed(uint256 indexed tokenId, uint256 amount);
event BatchDistributionProcessed(uint256[] tokenIds, uint256 totalAmount);
event ThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);
event BalanceWithdrawn(address indexed recipient, uint256 amount);
event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);
event FeeWithdrawn(uint256 amount);
```

## Security Considerations

1. **Access Control**
   - Owner-only administrative functions
   - Recipient verification
   - Distribution authorization

2. **Economic Security**
   - Threshold enforcement
   - Share validation
   - Fee calculation accuracy

3. **Operational Security**
   - Reentrancy protection
   - Balance tracking
   - Gas optimization

## Integration Guide

### Single Distribution
```solidity
// Distribute royalties for a single token
address[] memory recipients = [artist, producer];
uint256[] memory shares = [80, 20];
royaltyDistributor.distributeRoyalties(
    tokenId,
    saleAmount,
    recipients,
    shares
);
```

### Batch Distribution
```solidity
// Process multiple distributions
uint256[] memory tokenIds = [token1, token2];
uint256[] memory amounts = [amount1, amount2];
address[][] memory recipients = [[artist1], [artist2]];
uint256[][] memory shares = [[100], [100]];
royaltyDistributor.batchDistribute(
    tokenIds,
    amounts,
    recipients,
    shares
);
```

### Balance Withdrawal
```solidity
// Withdraw accumulated royalties
royaltyDistributor.withdrawBalance();
```

## Testing

The contract includes comprehensive tests in `test/RoyaltyDistributor.t.sol`:
- Distribution logic
- Batch processing
- Fee calculations
- Balance management
- Access control

## Deployment

Required parameters:
- Initial distribution threshold
- Platform fee percentage
- Fee recipient address

## Gas Optimization

1. Batch processing support
2. Efficient storage layout
3. Minimal state changes
4. Optimized calculations

## Audits

Focus areas:
1. Distribution logic
2. Fee handling
3. Access control
4. Balance management
5. Gas optimization
