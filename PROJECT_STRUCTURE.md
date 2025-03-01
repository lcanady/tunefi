# TuneFi Project Structure

## Overview

The TuneFi project has been reorganized into a cleaner, more modular structure:

```
tunefi/
├── api/                  # Backend API and indexer service
│   ├── src/              # Source code
│   │   ├── config/       # Configuration files
│   │   ├── middleware/   # Express middleware
│   │   ├── models/       # Mongoose models
│   │   ├── routes/       # API routes
│   │   ├── types/        # TypeScript type definitions
│   │   └── utils/        # Utility functions
│   ├── tests/            # Test files
│   │   ├── integration/  # Integration tests
│   │   └── unit/         # Unit tests
│   └── README.md         # API documentation
│
├── contracts/            # Smart contracts
│   ├── src/              # Contract source files
│   │   ├── TuneToken.sol
│   │   ├── MusicNFT.sol
│   │   └── ...
│   ├── test/             # Contract tests
│   ├── script/           # Deployment scripts
│   ├── foundry.toml      # Foundry configuration
│   └── README.md         # Contracts documentation
│
├── docs/                 # Project documentation
│   ├── architecture/
│   ├── contracts/
│   └── ...
│
├── lib/                  # External libraries (Foundry dependencies)
│
├── .github/              # GitHub workflows and configuration
│
├── README.md             # Main project README
└── PROJECT_STRUCTURE.md  # This file
```

## Key Components

### Smart Contracts (`/contracts`)

The smart contracts that power the TuneFi platform:

- **TuneToken**: The platform's utility token
- **MusicNFT**: NFT implementation for music ownership
- **Marketplace**: For buying and selling music NFTs
- **RoyaltyDistributor**: Handles royalty payments to rights holders
- **StakingContract**: Token staking mechanism
- **Governor**: DAO governance implementation
- **FanEngagement**: Fan interaction and rewards system
- **RecommendationGraph**: Music recommendation system
- **TuneAccessControl**: Role-based access control

### API Service (`/api`)

Backend indexing service that processes blockchain data:

- RESTful API for querying contract data
- Support for multiple networks
- Contract type classification
- Swagger API documentation

### Documentation (`/docs`)

Comprehensive documentation for the project:

- Architecture diagrams
- Contract specifications
- Deployment guides
- Development workflows
- Feature descriptions
- Integration guides
- Testing procedures
- Tokenomics details

### External Libraries (`/lib`)

Dependencies managed by Foundry:

- OpenZeppelin contracts
- Forge standard library
- Other external dependencies

### GitHub Configuration (`/.github`)

GitHub-specific configuration:

- CI/CD workflows
- Issue templates
- Pull request templates 