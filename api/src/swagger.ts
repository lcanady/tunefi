import swaggerJsdoc from 'swagger-jsdoc';

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'TuneFi Indexer API',
      version: '1.0.0',
      description: 'API documentation for the TuneFi Indexer service',
      license: {
        name: 'MIT',
        url: 'https://opensource.org/licenses/MIT',
      },
      contact: {
        name: 'TuneFi',
        url: 'https://tunefi.io',
        email: 'info@tunefi.io',
      },
    },
    servers: [
      {
        url: '/api/v1',
        description: 'Development server',
      },
    ],
    components: {
      schemas: {
        Contract: {
          type: 'object',
          required: ['address', 'network', 'type'],
          properties: {
            _id: {
              type: 'string',
              description: 'The auto-generated MongoDB ID',
            },
            address: {
              type: 'string',
              description: 'The Ethereum address of the contract',
            },
            name: {
              type: 'string',
              description: 'The name of the contract',
            },
            type: {
              type: 'string',
              enum: ['ERC20', 'ERC721', 'ERC1155', 'OTHER'],
              description: 'The type of the contract',
            },
            network: {
              type: 'string',
              description: 'The blockchain network the contract is deployed on',
            },
            deployedAt: {
              type: 'string',
              format: 'date-time',
              description: 'The timestamp when the contract was deployed',
            },
            lastIndexedBlock: {
              type: 'integer',
              description: 'The last block that was indexed for this contract',
            },
            isVerified: {
              type: 'boolean',
              description: 'Whether the contract is verified',
            },
            metadata: {
              type: 'object',
              description: 'Additional metadata for the contract',
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'The timestamp when the record was created',
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'The timestamp when the record was last updated',
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            message: {
              type: 'string',
              description: 'Error message',
            },
            code: {
              type: 'string',
              description: 'Error code',
            },
          },
        },
      },
    },
  },
  apis: ['./src/routes/*.ts'], // Path to the API routes
};

const swaggerSpecs = swaggerJsdoc(options);

export { swaggerSpecs };