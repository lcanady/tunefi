# TuneFi Platform

TuneFi is a decentralized platform for the music industry, enabling artists, fans, and stakeholders to interact in a transparent and fair ecosystem.

## Project Structure

The project is organized into the following main components:

### `/contracts`

Smart contracts that power the TuneFi platform:

- **TuneToken**: The platform's utility token
- **MusicNFT**: NFT implementation for music ownership
- **Marketplace**: For buying and selling music NFTs
- **RoyaltyDistributor**: Handles royalty payments to rights holders
- **StakingContract**: Token staking mechanism
- **Governor**: DAO governance implementation
- **FanEngagement**: Fan interaction and rewards system
- **RecommendationGraph**: Music recommendation system
- **TuneAccessControl**: Role-based access control

### `/api`

Backend indexing service that processes blockchain data:

- RESTful API for querying contract data
- Support for multiple networks
- Contract type classification
- Swagger API documentation

## Getting Started

### Smart Contracts

```bash
cd contracts
forge build
forge test
```

See the [contracts README](contracts/README.md) for more details.

### API Service

```bash
cd api
npm install
npm run dev
```

See the [API README](api/README.md) for more details.

## License

[MIT](LICENSE)
