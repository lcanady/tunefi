# TuneFi Deployment Guide

## Overview
This document outlines the deployment process for the TuneFi platform, including contract deployment sequence, configuration requirements, and post-deployment verification steps.

## Prerequisites

### Development Environment
- Node.js v16+
- Foundry
- Git
- Hardhat (optional)

### Network Requirements
- Ethereum mainnet/testnet RPC
- Archive node access
- Gas estimation tools
- Network monitoring

### Security Requirements
- Multi-sig wallet
- Hardware wallet
- Secure key management
- Audit completion

## Deployment Sequence

### 1. Core Token Contracts
```bash
# Deploy TuneToken
forge create src/TuneToken.sol:TuneToken \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Deploy MusicNFT
forge create src/MusicNFT.sol:MusicNFT \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args $ROYALTY_DISTRIBUTOR
```

### 2. Platform Contracts
```bash
# Deploy RoyaltyDistributor
forge create src/RoyaltyDistributor.sol:RoyaltyDistributor \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Deploy Marketplace
forge create src/Marketplace.sol:Marketplace \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args $MUSIC_NFT $ROYALTY_DISTRIBUTOR
```

### 3. Feature Contracts
```bash
# Deploy RecommendationGraph
forge create src/RecommendationGraph.sol:RecommendationGraph \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY

# Deploy FanEngagement
forge create src/FanEngagement.sol:FanEngagement \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY
```

## Configuration Steps

### 1. Access Control Setup
```solidity
// Set up roles
accessControl.createRole("PLATFORM_ADMIN", DEFAULT_ADMIN_ROLE);
accessControl.createRole("ARTIST", PLATFORM_ADMIN);
accessControl.createRole("MODERATOR", PLATFORM_ADMIN);

// Grant initial roles
accessControl.grantRole(PLATFORM_ADMIN, adminAddress);
```

### 2. Token Configuration
```solidity
// Configure token parameters
tuneToken.updateDistributionThreshold(distributionThreshold);
tuneToken.updatePlatformFee(platformFee);

// Set up initial distribution
tuneToken.createVestingSchedule(
    teamAddress,
    teamAllocation,
    startTime,
    vestingDuration,
    true
);
```

### 3. Platform Settings
```solidity
// Configure marketplace
marketplace.updatePlatformFee(marketplaceFee);
marketplace.setPaymentToken(tuneToken.address);

// Configure royalty distributor
royaltyDistributor.updateDistributionThreshold(threshold);
```

## Verification Steps

### 1. Contract Verification
```bash
# Verify TuneToken
forge verify-contract $TUNE_TOKEN_ADDRESS src/TuneToken.sol:TuneToken \
  --chain-id 1 \
  --num-of-optimizations 200

# Verify MusicNFT
forge verify-contract $MUSIC_NFT_ADDRESS src/MusicNFT.sol:MusicNFT \
  --chain-id 1 \
  --constructor-args $(cast abi-encode "constructor(address)" $ROYALTY_DISTRIBUTOR)
```

### 2. Functional Testing
```bash
# Test token transfers
cast send $TUNE_TOKEN_ADDRESS "transfer(address,uint256)" $TEST_ADDRESS 1000000000000000000 \
  --private-key $PRIVATE_KEY

# Test NFT minting
cast send $MUSIC_NFT_ADDRESS "mintTrack(string,uint256,address[],uint256[])" "ipfs://test" 1 [$ARTIST] [100] \
  --private-key $PRIVATE_KEY
```

### 3. Integration Testing
```bash
# Test marketplace listing
cast send $MARKETPLACE_ADDRESS "createListing(uint256,uint256,uint256)" 1 1000000000000000000 86400 \
  --private-key $PRIVATE_KEY

# Test royalty distribution
cast send $ROYALTY_DISTRIBUTOR_ADDRESS "distributeRoyalties(uint256,uint256)" 1 1000000000000000000 \
  --private-key $PRIVATE_KEY
```

## Post-Deployment Tasks

### 1. Security Measures
- Enable emergency pause
- Set up monitoring
- Configure alerts
- Backup deployment data

### 2. Documentation
- Update addresses
- Document versions
- Record parameters
- Update interfaces

### 3. Community
- Announce deployment
- Share contracts
- Update resources
- Enable support

## Maintenance Procedures

### 1. Upgrades
- Proposal creation
- Community review
- Testing process
- Execution steps

### 2. Emergency Response
- Issue detection
- System pause
- Fix deployment
- Recovery process

### 3. Monitoring
- Contract events
- Transaction volume
- Gas usage
- Error rates

## Network Specifics

### Ethereum Mainnet
```bash
export NETWORK_NAME="mainnet"
export RPC_URL="https://mainnet.infura.io/v3/YOUR-PROJECT-ID"
export CHAIN_ID=1
export BLOCK_EXPLORER="https://etherscan.io"
```

### Polygon
```bash
export NETWORK_NAME="polygon"
export RPC_URL="https://polygon-rpc.com"
export CHAIN_ID=137
export BLOCK_EXPLORER="https://polygonscan.com"
```

## Deployment Checklist

### Pre-Deployment
- [ ] Audit completed
- [ ] Multi-sig setup
- [ ] Gas estimation
- [ ] Test coverage

### Deployment
- [ ] Core contracts
- [ ] Platform contracts
- [ ] Feature contracts
- [ ] Configuration

### Post-Deployment
- [ ] Verification
- [ ] Testing
- [ ] Documentation
- [ ] Monitoring

## Troubleshooting

### Common Issues
1. Gas estimation failures
2. Contract verification errors
3. Integration issues
4. Permission problems

### Solutions
1. Gas price adjustment
2. Compiler version check
3. Interface verification
4. Role verification

## Scripts

### deployment.sh
```bash
#!/bin/bash

# Load environment variables
source .env

# Deploy core contracts
echo "Deploying core contracts..."
TUNE_TOKEN=$(forge create src/TuneToken.sol:TuneToken)
MUSIC_NFT=$(forge create src/MusicNFT.sol:MusicNFT)

# Deploy platform contracts
echo "Deploying platform contracts..."
ROYALTY_DISTRIBUTOR=$(forge create src/RoyaltyDistributor.sol:RoyaltyDistributor)
MARKETPLACE=$(forge create src/Marketplace.sol:Marketplace)

# Configure contracts
echo "Configuring contracts..."
cast send $TUNE_TOKEN "updateDistributionThreshold(uint256)" 1000000000000000000
cast send $MARKETPLACE "updatePlatformFee(uint256)" 250

# Verify contracts
echo "Verifying contracts..."
forge verify-contract $TUNE_TOKEN src/TuneToken.sol:TuneToken
forge verify-contract $MUSIC_NFT src/MusicNFT.sol:MusicNFT
```

### verify.sh
```bash
#!/bin/bash

# Load addresses
source .deployment-addresses

# Verify all contracts
for contract in "${!ADDRESSES[@]}"; do
  forge verify-contract ${ADDRESSES[$contract]} "src/$contract.sol:$contract" \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200
done
``` 