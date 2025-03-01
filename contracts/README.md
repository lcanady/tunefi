# TuneFi Smart Contracts

Smart contracts that power the TuneFi platform, enabling decentralized music ownership, royalty distribution, and fan engagement.

## Contracts

- **TuneToken.sol**: ERC20 token with vesting, staking, and service tiers
- **MusicNFT.sol**: ERC1155 NFT for music tracks with version control
- **RoyaltyDistributor.sol**: Handles royalty distribution for collaborators
- **Marketplace.sol**: NFT trading with automated royalty handling
- **StakingContract.sol**: Token staking mechanism with rewards
- **Governor.sol**: DAO governance implementation
- **FanEngagement.sol**: Fan interaction and rewards system
- **RecommendationGraph.sol**: Music recommendation system
- **TuneAccessControl.sol**: Role-based access control

## Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- Git

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/tunefi.git
cd tunefi/contracts

# Install dependencies
forge install
```

### Building

```bash
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/MusicNFT.t.sol

# Run tests with verbosity
forge test -vvv
```

### Deployment

```bash
# Deploy to local network
anvil
forge script script/Deploy.s.sol --fork-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

## Security Features

- Role-based access control
- Pausable contracts
- Safe math operations (Solidity 0.8.20)
- Reentrancy protection
- ERC1155 receiver validation

## License

[MIT](../LICENSE) 