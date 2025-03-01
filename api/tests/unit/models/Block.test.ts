import { jest } from '@jest/globals';

// Mock mongoose completely
jest.mock('mongoose', () => {
  const mockObjectId = () => ({
    toString: () => 'mock-object-id',
    equals: (other: any) => other?.toString() === 'mock-object-id'
  });

  const mockCollections = jest.fn().mockImplementation(() => Promise.resolve([]));

  return {
    Types: {
      ObjectId: jest.fn().mockImplementation(mockObjectId)
    },
    Schema: jest.fn(),
    model: jest.fn(),
    connect: jest.fn(),
    disconnect: jest.fn(),
    connection: {
      readyState: 1,
      db: {
        collection: jest.fn(),
        collections: mockCollections,
        dropDatabase: jest.fn()
      },
      dropDatabase: jest.fn(),
      on: jest.fn(),
      once: jest.fn(),
      close: jest.fn()
    }
  };
});

// Import actual types we need
import type { IBlock } from '../../../src/models/Block';

// Types
interface MockBlockData {
  _id?: any;
  number: number;
  hash: string;
  parentHash: string;
  timestamp: number;
  gasUsed?: number;
  gasLimit?: number;
  baseFeePerGas?: string;
  difficulty?: string;
  totalDifficulty?: string;
  size?: number;
  nonce?: string;
  miner?: string;
  extraData?: string;
  transactionCount?: number;
  createdAt?: Date;
  updatedAt?: Date;
}

type MockCreateFunction = (data: Partial<MockBlockData>) => Promise<MockBlockData & { _id: any }>;
type MockFindFunction = (query: any) => Promise<Array<MockBlockData & { _id: any }>>;

// Create mock Block model
const mockBlockModel = {
  create: jest.fn() as jest.MockedFunction<MockCreateFunction>,
  deleteMany: jest.fn(),
  findOne: jest.fn(),
  find: jest.fn() as jest.MockedFunction<MockFindFunction>,
  updateOne: jest.fn(),
  deleteOne: jest.fn()
};

// Mock Block module
jest.mock('../../../src/models/Block', () => ({
  Block: mockBlockModel,
  IBlock: jest.fn()
}));

describe('Block Model', () => {
  beforeEach(() => {
    // Reset all mocks
    jest.clearAllMocks();

    // Setup mock create function
    mockBlockModel.create.mockImplementation((data: Partial<MockBlockData>) => 
      Promise.resolve({
        _id: {
          toString: () => 'mock-block-id',
          equals: (other: any) => other?.toString() === 'mock-block-id'
        },
        number: data.number ?? 0,
        hash: data.hash ?? '',
        parentHash: data.parentHash ?? '',
        timestamp: data.timestamp ?? Date.now(),
        gasUsed: data.gasUsed,
        gasLimit: data.gasLimit,
        baseFeePerGas: data.baseFeePerGas,
        difficulty: data.difficulty,
        totalDifficulty: data.totalDifficulty,
        size: data.size,
        nonce: data.nonce,
        miner: data.miner?.toLowerCase(),
        extraData: data.extraData,
        transactionCount: data.transactionCount,
        createdAt: new Date(),
        updatedAt: new Date(),
        toString: () => 'mock-block'
      } as MockBlockData & { _id: any })
    );
  });

  const validBlock: MockBlockData = {
    number: 12345678,
    hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
    parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
    timestamp: Date.now(),
    gasUsed: 1000000,
    gasLimit: 2000000,
    baseFeePerGas: '20000000000',
    difficulty: '2500000000000000',
    totalDifficulty: '25000000000000000000',
    size: 50000,
    nonce: '0x1234567890abcdef',
    miner: '0x1234567890123456789012345678901234567890',
    extraData: '0x',
    transactionCount: 100
  };

  it('should create a block with valid fields', async () => {
    const block = await mockBlockModel.create(validBlock);
    expect(block.number).toBe(validBlock.number);
    expect(block.hash).toBe(validBlock.hash);
    expect(block.parentHash).toBe(validBlock.parentHash);
    expect(block.timestamp).toBe(validBlock.timestamp);
    expect(block.gasUsed).toBe(validBlock.gasUsed);
    expect(block.gasLimit).toBe(validBlock.gasLimit);
    expect(block.baseFeePerGas).toBe(validBlock.baseFeePerGas);
    expect(block.difficulty).toBe(validBlock.difficulty);
    expect(block.totalDifficulty).toBe(validBlock.totalDifficulty);
    expect(block.size).toBe(validBlock.size);
    expect(block.nonce).toBe(validBlock.nonce);
    expect(block.miner).toBe(validBlock.miner?.toLowerCase());
    expect(block.extraData).toBe(validBlock.extraData);
    expect(block.transactionCount).toBe(validBlock.transactionCount);
  });

  it('should require block number', async () => {
    mockBlockModel.create.mockRejectedValueOnce(new Error('Validation failed'));
    const blockWithoutNumber = {
      hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      timestamp: Date.now()
    };

    await expect(mockBlockModel.create(blockWithoutNumber)).rejects.toThrow();
  });

  it('should validate block hash format', async () => {
    mockBlockModel.create.mockRejectedValueOnce(new Error('Invalid block hash format'));
    const blockWithInvalidHash = {
      number: 12345678,
      hash: 'invalid_hash',
      parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      timestamp: Date.now()
    };

    await expect(mockBlockModel.create(blockWithInvalidHash)).rejects.toThrow();
  });

  it('should enforce unique block number', async () => {
    mockBlockModel.create
      .mockResolvedValueOnce({
        ...validBlock,
        _id: {
          toString: () => 'mock-block-id-1',
          equals: (other: any) => other?.toString() === 'mock-block-id-1'
        }
      })
      .mockRejectedValueOnce(new Error('Duplicate key error'));

    await mockBlockModel.create(validBlock);
    await expect(mockBlockModel.create({
      ...validBlock,
      hash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
    })).rejects.toThrow();
  });

  it('should enforce unique block hash', async () => {
    mockBlockModel.create
      .mockResolvedValueOnce({
        ...validBlock,
        _id: {
          toString: () => 'mock-block-id-1',
          equals: (other: any) => other?.toString() === 'mock-block-id-1'
        }
      })
      .mockRejectedValueOnce(new Error('Duplicate key error'));

    await mockBlockModel.create(validBlock);
    await expect(mockBlockModel.create({
      ...validBlock,
      number: 12345679
    })).rejects.toThrow();
  });

  it('should validate miner address format', async () => {
    mockBlockModel.create.mockRejectedValueOnce(new Error('Invalid miner address format'));
    const blockWithInvalidMiner = {
      number: 12345678,
      hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      timestamp: Date.now(),
      miner: 'invalid_miner'
    };

    await expect(mockBlockModel.create(blockWithInvalidMiner)).rejects.toThrow();
  });

  it('should validate positive gas values', async () => {
    mockBlockModel.create.mockRejectedValueOnce(new Error('Gas values must be positive'));
    const blockWithNegativeGas = {
      number: 12345678,
      hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      timestamp: Date.now(),
      gasUsed: -1,
      gasLimit: -1
    };

    await expect(mockBlockModel.create(blockWithNegativeGas)).rejects.toThrow();
  });

  it('should support querying by block range', async () => {
    const mockBlock = {
      ...validBlock,
      number: 200,
      _id: {
        toString: () => 'mock-block-id-2',
        equals: (other: any) => other?.toString() === 'mock-block-id-2'
      }
    };

    mockBlockModel.find.mockResolvedValueOnce([mockBlock]);

    const result = await mockBlockModel.find({
      number: { $gte: 150, $lte: 250 }
    });

    expect(result).toHaveLength(1);
    expect(result[0].number).toBe(200);
  });

  it('should support querying by timestamp range', async () => {
    const now = Date.now();
    const hourAgo = now - 3600000;

    const mockBlocks = [
      {
        ...validBlock,
        number: 200,
        timestamp: hourAgo,
        _id: {
          toString: () => 'mock-block-id-2',
          equals: (other: any) => other?.toString() === 'mock-block-id-2'
        }
      },
      {
        ...validBlock,
        number: 300,
        timestamp: now,
        _id: {
          toString: () => 'mock-block-id-3',
          equals: (other: any) => other?.toString() === 'mock-block-id-3'
        }
      }
    ];

    mockBlockModel.find.mockResolvedValueOnce(mockBlocks);

    const result = await mockBlockModel.find({
      timestamp: { $gte: hourAgo, $lte: now }
    });

    expect(result).toHaveLength(2);
    expect(result.map((block: MockBlockData) => block.number).sort()).toEqual([200, 300]);
  });

  it('should create timestamps automatically', async () => {
    const block = await mockBlockModel.create({
      number: 12345678,
      hash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      parentHash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
      timestamp: Date.now()
    });

    expect(block.createdAt).toBeDefined();
    expect(block.updatedAt).toBeDefined();
    expect(block.createdAt).toBeInstanceOf(Date);
    expect(block.updatedAt).toBeInstanceOf(Date);
  });
}); 