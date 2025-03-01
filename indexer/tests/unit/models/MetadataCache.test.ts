import mongoose from 'mongoose';
import { MetadataCache, MetadataCacheStatus, IMetadataCache } from '../../../src/models/MetadataCache';
import { Contract, ContractType, IContract } from '../../../src/models/Contract';

describe('MetadataCache Model', () => {
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
    await MetadataCache.deleteMany({});
  });

  it('should create a metadata cache with valid fields', async () => {
    const validMetadata = {
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: {
        name: 'Token #1',
        description: 'A test token',
        image: 'https://example.com/images/1.png',
        attributes: [
          { trait_type: 'Background', value: 'Blue' },
          { trait_type: 'Eyes', value: 'Green' }
        ]
      },
      lastFetched: Date.now(),
      status: MetadataCacheStatus.SUCCESS,
      retryCount: 0
    };

    const cache = await MetadataCache.create(validMetadata);
    expect(cache.contract.toString()).toBe(contract._id?.toString());
    expect(cache.tokenId).toBe(validMetadata.tokenId);
    expect(cache.uri).toBe(validMetadata.uri);
    expect(cache.metadata).toEqual(validMetadata.metadata);
    expect(Math.abs(cache.lastFetched! - validMetadata.lastFetched)).toBeLessThan(1000); // Allow 1 second difference
    expect(cache.status).toBe(validMetadata.status);
    expect(cache.retryCount).toBe(validMetadata.retryCount);
  });

  it('should require contract reference', async () => {
    const metadataWithoutContract = {
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1' }
    };

    await expect(MetadataCache.create(metadataWithoutContract)).rejects.toThrow();
  });

  it('should require tokenId', async () => {
    const metadataWithoutTokenId = {
      contract: contract._id,
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1' }
    };

    await expect(MetadataCache.create(metadataWithoutTokenId)).rejects.toThrow();
  });

  it('should enforce unique contract and tokenId combination', async () => {
    const metadata = {
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1' },
      status: MetadataCacheStatus.SUCCESS
    };

    await MetadataCache.create(metadata);
    await expect(MetadataCache.create(metadata)).rejects.toThrow();
  });

  it('should validate URI format', async () => {
    const metadataWithInvalidUri = {
      contract: contract._id,
      tokenId: '1',
      uri: 'invalid-uri',
      metadata: { name: 'Token #1' },
      status: MetadataCacheStatus.SUCCESS
    };

    await expect(MetadataCache.create(metadataWithInvalidUri)).rejects.toThrow();
  });

  it('should support updating metadata', async () => {
    const cache = await MetadataCache.create({
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1', description: 'Original description' },
      status: MetadataCacheStatus.SUCCESS
    });

    const updatedMetadata = {
      name: 'Token #1',
      description: 'Updated description',
      image: 'https://example.com/images/1.png'
    };

    cache.metadata = updatedMetadata;
    cache.lastFetched = Date.now();
    await cache.save();

    const updatedCache = await MetadataCache.findById(cache._id);
    expect(updatedCache?.metadata).toEqual(updatedMetadata);
  });

  it('should support error tracking', async () => {
    const cache = await MetadataCache.create({
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      status: MetadataCacheStatus.PENDING
    });

    const error = 'Failed to fetch metadata';
    cache.error = error;
    cache.status = MetadataCacheStatus.FAILED;
    cache.retryCount = 1;
    await cache.save();

    const updatedCache = await MetadataCache.findById(cache._id);
    expect(updatedCache?.error).toBe(error);
    expect(updatedCache?.status).toBe(MetadataCacheStatus.FAILED);
    expect(updatedCache?.retryCount).toBe(1);
  });

  it('should support querying by status', async () => {
    await Promise.all([
      MetadataCache.create({
        contract: contract._id,
        tokenId: '1',
        uri: 'https://api.example.com/token/1',
        status: MetadataCacheStatus.SUCCESS
      }),
      MetadataCache.create({
        contract: contract._id,
        tokenId: '2',
        uri: 'https://api.example.com/token/2',
        status: MetadataCacheStatus.PENDING
      }),
      MetadataCache.create({
        contract: contract._id,
        tokenId: '3',
        uri: 'https://api.example.com/token/3',
        status: MetadataCacheStatus.FAILED
      })
    ]);

    const successfulCaches = await MetadataCache.find({ status: MetadataCacheStatus.SUCCESS });
    expect(successfulCaches).toHaveLength(1);
    expect(successfulCaches[0].tokenId).toBe('1');

    const pendingCaches = await MetadataCache.find({ status: MetadataCacheStatus.PENDING });
    expect(pendingCaches).toHaveLength(1);
    expect(pendingCaches[0].tokenId).toBe('2');

    const failedCaches = await MetadataCache.find({ status: MetadataCacheStatus.FAILED });
    expect(failedCaches).toHaveLength(1);
    expect(failedCaches[0].tokenId).toBe('3');
  });

  it('should create timestamps automatically', async () => {
    const cache = await MetadataCache.create({
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1' },
      status: MetadataCacheStatus.SUCCESS
    });

    expect(cache.createdAt).toBeDefined();
    expect(cache.updatedAt).toBeDefined();
    expect(cache.createdAt).toBeInstanceOf(Date);
    expect(cache.updatedAt).toBeInstanceOf(Date);
  });

  it('should update timestamps on modification', async () => {
    const cache = await MetadataCache.create({
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      metadata: { name: 'Token #1' },
      status: MetadataCacheStatus.SUCCESS
    });

    const originalUpdatedAt = cache.updatedAt;
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second

    cache.metadata = { name: 'Updated Token #1' };
    await cache.save();

    expect(cache.updatedAt.getTime()).toBeGreaterThan(originalUpdatedAt.getTime());
  });

  it('should validate metadata structure', async () => {
    const metadataWithInvalidAttributes = {
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      status: MetadataCacheStatus.SUCCESS,
      metadata: {
        name: 'Token #1',
        attributes: [
          { value: 'Blue' } // Missing trait_type
        ]
      }
    };

    await expect(MetadataCache.create(metadataWithInvalidAttributes)).rejects.toThrow();
  });

  it('should validate image URL in metadata', async () => {
    const metadataWithInvalidImage = {
      contract: contract._id,
      tokenId: '1',
      uri: 'https://api.example.com/token/1',
      status: MetadataCacheStatus.SUCCESS,
      metadata: {
        name: 'Token #1',
        image: 'invalid-image-url'
      }
    };

    await expect(MetadataCache.create(metadataWithInvalidImage)).rejects.toThrow();
  });
}); 