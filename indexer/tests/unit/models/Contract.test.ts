import mongoose from 'mongoose';
import { Contract, IContract } from '../../../src/models/Contract';
import { connectDatabase, closeDatabase } from '../../../src/config/database';

describe('Contract Model', () => {
  jest.setTimeout(30000); // Increase timeout to 30 seconds

  beforeAll(async () => {
    await connectDatabase();
  });

  afterAll(async () => {
    await closeDatabase();
  });

  beforeEach(async () => {
    await Contract.deleteMany({});
  });

  it('should create a contract successfully', async () => {
    const validContract = {
      address: '0x123456789abcdef',
      name: 'Test Contract',
      type: 'ERC721' as const,
      network: 'ethereum',
    };

    const savedContract = await Contract.create(validContract);
    expect(savedContract._id).toBeDefined();
    expect(savedContract.address).toBe(validContract.address);
    expect(savedContract.isActive).toBe(true);
    expect(savedContract.createdAt).toBeDefined();
    expect(savedContract.updatedAt).toBeDefined();
  });

  it('should fail to create contract without required fields', async () => {
    const invalidContract = {
      address: '0x123456789abcdef',
      // Missing required fields
    };

    await expect(Contract.create(invalidContract)).rejects.toThrow();
  });

  it('should enforce unique address constraint', async () => {
    const contract = {
      address: '0x123456789abcdef',
      name: 'Test Contract',
      type: 'ERC721' as const,
      network: 'ethereum',
    };

    await Contract.create(contract);
    await expect(Contract.create(contract)).rejects.toThrow();
  });

  it('should enforce enum values for type field', async () => {
    const invalidContract = {
      address: '0x123456789abcdef',
      name: 'Test Contract',
      type: 'INVALID_TYPE',
      network: 'ethereum',
    };

    await expect(Contract.create(invalidContract)).rejects.toThrow();
  });

  it('should update contract successfully', async () => {
    const contract = await Contract.create({
      address: '0x123456789abcdef',
      name: 'Test Contract',
      type: 'ERC721' as const,
      network: 'ethereum',
    });

    const updatedName = 'Updated Contract';
    await Contract.findByIdAndUpdate(contract._id, { name: updatedName });
    
    const updatedContract = await Contract.findById(contract._id);
    expect(updatedContract?.name).toBe(updatedName);
  });
}); 