import mongoose from 'mongoose';
import { IndexingStatus, IndexingStatusType, IIndexingStatus } from '../../../src/models/IndexingStatus';
import { Contract, ContractType, IContract } from '../../../src/models/Contract';

describe('IndexingStatus Model', () => {
  let contract: IContract;

  beforeAll(async () => {
    // Create a test contract
    contract = await Contract.create({
      address: '0x1234567890123456789012345678901234567890',
      name: 'Test NFT',
      type: ContractType.ERC721,
      network: 'ethereum',
      symbol: 'TEST'
    });
  });

  beforeEach(async () => {
    await IndexingStatus.deleteMany({});
  });

  it('should create an indexing status with valid fields', async () => {
    const validStatus = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      error: null,
      progress: 75.5,
      startBlock: 12345000,
      endBlock: 12346000,
      currentBlock: 12345678
    };

    const status = await IndexingStatus.create(validStatus);
    expect(status.contract.toString()).toBe(contract._id?.toString());
    expect(status.lastIndexedBlock).toBe(validStatus.lastIndexedBlock);
    expect(Math.abs(status.lastIndexedAt - validStatus.lastIndexedAt)).toBeLessThan(1000); // Allow 1 second difference
    expect(status.isIndexing).toBe(validStatus.isIndexing);
    expect(status.status).toBe(validStatus.status);
    expect(status.error).toBe(validStatus.error);
    expect(status.progress).toBe(validStatus.progress);
    expect(status.startBlock).toBe(validStatus.startBlock);
    expect(status.endBlock).toBe(validStatus.endBlock);
    expect(status.currentBlock).toBe(validStatus.currentBlock);
  });

  it('should require contract reference', async () => {
    const statusWithoutContract = {
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING
    };

    await expect(IndexingStatus.create(statusWithoutContract)).rejects.toThrow();
  });

  it('should enforce unique contract constraint', async () => {
    const status = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING
    };

    await IndexingStatus.create(status);
    await expect(IndexingStatus.create(status)).rejects.toThrow();
  });

  it('should validate block numbers are positive', async () => {
    const statusWithNegativeBlocks = {
      contract: contract._id,
      lastIndexedBlock: -1,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      startBlock: -100,
      endBlock: -50,
      currentBlock: -75
    };

    await expect(IndexingStatus.create(statusWithNegativeBlocks)).rejects.toThrow();
  });

  it('should validate progress is between 0 and 100', async () => {
    const statusWithInvalidProgress = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      progress: 150
    };

    await expect(IndexingStatus.create(statusWithInvalidProgress)).rejects.toThrow();
  });

  it('should validate status enum values', async () => {
    const statusWithInvalidStatus = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: 'invalid_status'
    };

    await expect(IndexingStatus.create(statusWithInvalidStatus)).rejects.toThrow();
  });

  it('should support updating indexing progress', async () => {
    const status = await IndexingStatus.create({
      contract: contract._id,
      lastIndexedBlock: 12345000,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      progress: 0,
      startBlock: 12345000,
      endBlock: 12346000,
      currentBlock: 12345000
    });

    const newProgress = 50;
    const newCurrentBlock = 12345500;
    
    status.progress = newProgress;
    status.currentBlock = newCurrentBlock;
    await status.save();

    const updatedStatus = await IndexingStatus.findById(status._id);
    expect(updatedStatus?.progress).toBe(newProgress);
    expect(updatedStatus?.currentBlock).toBe(newCurrentBlock);
  });

  it('should support error handling', async () => {
    const status = await IndexingStatus.create({
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING
    });

    const error = 'RPC node connection failed';
    status.error = error;
    status.status = IndexingStatusType.FAILED;
    status.isIndexing = false;
    await status.save();

    const updatedStatus = await IndexingStatus.findById(status._id);
    expect(updatedStatus?.error).toBe(error);
    expect(updatedStatus?.status).toBe(IndexingStatusType.FAILED);
    expect(updatedStatus?.isIndexing).toBe(false);
  });

  it('should create timestamps automatically', async () => {
    const status = await IndexingStatus.create({
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING
    });

    expect(status.createdAt).toBeDefined();
    expect(status.updatedAt).toBeDefined();
    expect(status.createdAt).toBeInstanceOf(Date);
    expect(status.updatedAt).toBeInstanceOf(Date);
  });

  it('should update timestamps on modification', async () => {
    const status = await IndexingStatus.create({
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING
    });

    const originalUpdatedAt = status.updatedAt;
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second

    status.progress = 50;
    await status.save();

    expect(status.updatedAt.getTime()).toBeGreaterThan(originalUpdatedAt.getTime());
  });

  it('should validate block range constraints', async () => {
    const statusWithInvalidRange = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      startBlock: 12346000,
      endBlock: 12345000,
      currentBlock: 12345500
    };

    await expect(IndexingStatus.create(statusWithInvalidRange)).rejects.toThrow();
  });

  it('should validate current block within range', async () => {
    const statusWithInvalidCurrentBlock = {
      contract: contract._id,
      lastIndexedBlock: 12345678,
      lastIndexedAt: Date.now(),
      isIndexing: true,
      status: IndexingStatusType.RUNNING,
      startBlock: 12345000,
      endBlock: 12346000,
      currentBlock: 12347000
    };

    await expect(IndexingStatus.create(statusWithInvalidCurrentBlock)).rejects.toThrow();
  });
}); 