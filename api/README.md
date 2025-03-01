# TuneFi API & Indexer

A blockchain indexing service that processes and stores contract data, transactions, and events for easy querying and analysis.

## Features

- RESTful API for managing blockchain contracts
- Support for multiple networks (Ethereum, Polygon, etc.)
- Contract type classification (ERC20, ERC721, ERC1155, OTHER)
- Swagger API documentation
- Comprehensive test suite

## Tech Stack

- Node.js & TypeScript
- Express.js for API endpoints
- MongoDB with Mongoose for data storage
- Jest for testing
- Swagger for API documentation

## Getting Started

### Prerequisites

- Node.js (v14+)
- MongoDB instance
- npm or yarn

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/tunefi.git
cd tunefi/api
```

2. Install dependencies
```bash
npm install
```

3. Set up environment variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Build the project
```bash
npm run build
```

5. Start the server
```bash
npm start
```

For development with hot-reload:
```bash
npm run dev
```

## API Documentation

API documentation is available at `/api/v1/docs` when the server is running.

### Key Endpoints

- `GET /api/v1/contracts` - List all contracts with filtering options
- `POST /api/v1/contracts` - Create a new contract
- `GET /api/v1/contracts/:address` - Get a specific contract by address
- `PATCH /api/v1/contracts/:address` - Update a contract
- `DELETE /api/v1/contracts/:address` - Delete a contract
- `GET /health` - Health check endpoint

## Testing

Run the test suite:

```bash
npm test
```

Run specific tests:

```bash
npm test -- tests/integration/routes/contracts.test.ts
```

## Development

### Code Structure

- `src/` - Source code
  - `models/` - Mongoose models
  - `routes/` - API routes
  - `middleware/` - Express middleware
  - `utils/` - Utility functions
  - `config/` - Configuration files
  - `types/` - TypeScript type definitions
- `tests/` - Test files
  - `unit/` - Unit tests
  - `integration/` - Integration tests

## License

[MIT](../LICENSE) 