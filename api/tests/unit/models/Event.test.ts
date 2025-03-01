import mongoose from 'mongoose';
import { Event } from '../../../src/models/Event';
import { Contract, ContractType, IContract } from '../../../src/models/Contract';

describe('Event Model', () => {
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
    await Event.deleteMany({});
  });

  it('should create an event with valid fields', async () => {
    const validEvent = {
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: 0,
      args: {
        from: '0x0000000000000000000000000000000000000000',
        to: '0x1234567890123456789012345678901234567890',
        tokenId: '1'
      },
      timestamp: Date.now()
    };

    const event = await Event.create(validEvent);
    expect(event.contract.toString()).toBe(contract._id?.toString());
    expect(event.name).toBe(validEvent.name);
    expect(event.signature).toBe(validEvent.signature);
    expect(event.blockNumber).toBe(validEvent.blockNumber);
    expect(event.transactionHash).toBe(validEvent.transactionHash);
    expect(event.logIndex).toBe(validEvent.logIndex);
    expect(event.args).toEqual(validEvent.args);
    expect(event.timestamp).toBe(validEvent.timestamp);
  });

  it('should require contract reference', async () => {
    const eventWithoutContract = {
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: 0
    };

    await expect(Event.create(eventWithoutContract)).rejects.toThrow();
  });

  it('should validate transaction hash format', async () => {
    const eventWithInvalidHash = {
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: 'invalid_hash',
      logIndex: 0
    };

    await expect(Event.create(eventWithInvalidHash)).rejects.toThrow();
  });

  it('should enforce unique compound index', async () => {
    const event = {
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: 0
    };

    await Event.create(event);
    await expect(Event.create(event)).rejects.toThrow();
  });

  it('should validate block number is positive', async () => {
    const eventWithNegativeBlock = {
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: -1,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: 0
    };

    await expect(Event.create(eventWithNegativeBlock)).rejects.toThrow();
  });

  it('should validate log index is non-negative', async () => {
    const eventWithNegativeLogIndex = {
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: -1
    };

    await expect(Event.create(eventWithNegativeLogIndex)).rejects.toThrow();
  });

  it('should support querying by block range', async () => {
    await Promise.all([
      Event.create({
        contract: contract._id,
        name: 'Transfer',
        signature: 'Transfer(address,address,uint256)',
        blockNumber: 100,
        transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        logIndex: 0
      }),
      Event.create({
        contract: contract._id,
        name: 'Transfer',
        signature: 'Transfer(address,address,uint256)',
        blockNumber: 200,
        transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567891',
        logIndex: 0
      }),
      Event.create({
        contract: contract._id,
        name: 'Transfer',
        signature: 'Transfer(address,address,uint256)',
        blockNumber: 300,
        transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567892',
        logIndex: 0
      })
    ]);

    const result = await Event.find({
      blockNumber: { $gte: 150, $lte: 250 }
    });

    expect(result).toHaveLength(1);
    expect(result[0].blockNumber).toBe(200);
  });

  it('should support querying by event name', async () => {
    await Promise.all([
      Event.create({
        contract: contract._id,
        name: 'Transfer',
        signature: 'Transfer(address,address,uint256)',
        blockNumber: 100,
        transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
        logIndex: 0
      }),
      Event.create({
        contract: contract._id,
        name: 'Approval',
        signature: 'Approval(address,address,uint256)',
        blockNumber: 101,
        transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567891',
        logIndex: 0
      })
    ]);

    const result = await Event.find({ name: 'Transfer' });
    expect(result).toHaveLength(1);
    expect(result[0].name).toBe('Transfer');
  });

  it('should create timestamps automatically', async () => {
    const event = await Event.create({
      contract: contract._id,
      name: 'Transfer',
      signature: 'Transfer(address,address,uint256)',
      blockNumber: 12345678,
      transactionHash: '0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      logIndex: 0
    });

    expect(event.createdAt).toBeDefined();
    expect(event.updatedAt).toBeDefined();
    expect(event.createdAt).toBeInstanceOf(Date);
    expect(event.updatedAt).toBeInstanceOf(Date);
  });
}); 