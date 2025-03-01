/**
 * @jest-environment node
 */

// Import jest first
import { jest } from '@jest/globals';

// Define types
interface IContract {
  address: string;
  type: string;
  name: string;
  symbol: string;
}

// Mock Contract module before imports
const mockCreate = jest.fn<(data: IContract) => Promise<IContract>>();
const mockFind = jest.fn<() => Promise<IContract[]>>();
const mockFindOne = jest.fn<(query: any) => Promise<IContract | null>>();
const mockCountDocuments = jest.fn<() => Promise<number>>();
const mockDeleteMany = jest.fn<() => Promise<{ acknowledged: boolean; deletedCount: number }>>();

jest.mock('../../../src/models/Contract', () => ({
  Contract: {
    create: mockCreate,
    find: mockFind,
    findOne: mockFindOne,
    countDocuments: mockCountDocuments,
    deleteMany: mockDeleteMany
  },
  ContractType: {
    ERC721: 'ERC721',
    ERC1155: 'ERC1155'
  }
}));

// Other imports
import request from 'supertest';
import { app } from '../../../src/app';
import { ContractType } from '../../../src/models/Contract';

describe('Contract Routes', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('POST /api/v1/contracts', () => {
    const validContract = {
      address: '0x1234567890123456789012345678901234567890',
      type: ContractType.ERC721,
      name: 'Test Contract',
      symbol: 'TEST'
    };

    it('should create a new contract with valid fields', async () => {
      mockFindOne.mockResolvedValue(null);
      mockCreate.mockImplementation(async (data) => ({
        ...validContract,
        _id: 'mock-id',
        createdAt: new Date(),
        updatedAt: new Date()
      }));

      const response = await request(app)
        .post('/api/v1/contracts')
        .send(validContract);

      expect(response.status).toBe(201);
      expect(response.body).toMatchObject(validContract);
    });

    it('should return 400 for invalid address format', async () => {
      const invalidContract = {
        ...validContract,
        address: 'invalid-address',
      };

      const response = await request(app)
        .post('/api/v1/contracts')
        .send(invalidContract);

      expect(response.status).toBe(400);
      expect(response.body.error).toBe('Invalid Ethereum address');
    });

    it('should return 409 for duplicate contract', async () => {
      mockFindOne.mockResolvedValue(validContract);

      const response = await request(app)
        .post('/api/v1/contracts')
        .send(validContract);

      expect(response.status).toBe(409);
      expect(response.body.error).toBe('Contract already exists');
    });
  });
}); 