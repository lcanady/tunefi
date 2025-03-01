# Deployment Scripts

This directory contains the deployment scripts for the TuneFi platform.

## Main Deployment Script

### Deploy.s.sol
The main deployment script that sets up all TuneFi contracts on a network. It handles:
- Contract deployment in the correct order
- Initial configuration
- Permission setup
- Token distribution

## Usage

### Local Development (Anvil)
1. Start local Anvil node:
```bash
anvil
```

2. Deploy contracts:
```bash
forge script script/Deploy.s.sol --fork-url http://localhost:8545 --broadcast
```

### Testnet Deployment
1. Set environment variables:
```bash
export RPC_URL=<your-rpc-url>
export PRIVATE_KEY=<your-private-key>
```

2. Deploy contracts:
```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

## Contract Deployment Order

1. AccessControl
2. TuneToken
3. MusicNFT
4. RoyaltyDistributor
5. StakingContract
6. Marketplace
7. RecommendationGraph
8. FanEngagement

## Initial Setup

### Permission Setup
- Creates ADMIN_ROLE and OPERATOR_ROLE
- Grants ADMIN_ROLE to deployer
- Grants OPERATOR_ROLE to necessary contracts

### Token Distribution
- 40% Community Treasury
- 30% Team & Advisors (vested)
- 20% Platform Development
- 10% Initial Liquidity

### Vesting Schedule
- Cliff: 180 days
- Duration: 720 days
- Revocable: Yes

## Configuration

The script uses the following constants that can be modified:
- INITIAL_SUPPLY: 1 billion TUNE tokens
- BASE_REWARD: 100 TUNE tokens
- PLATFORM_FEE: 2.5%
- MIN_INTERACTIONS: 5

## Verification

After deployment, verify contract source code:
```bash
forge verify-contract <contract-address> src/ContractName.sol:ContractName --chain <chain-id>
```
