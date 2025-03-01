import request from 'supertest';
import sinon from 'sinon';
import { app } from '../../../src/app';
import { Contract, ContractType, IContract } from '../../../src/models/Contract';
import mongoose from 'mongoose';

describe('Contract Routes', () => {
  const API_PREFIX = '/api/v1';
  let sandbox: sinon.SinonSandbox;
  
  beforeEach(() => {
    sandbox = sinon.createSandbox();
  });

  afterEach(() => {
    sandbox.restore();
  });

  const validContract = {
    address: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    type: ContractType.ERC721,
    network: 'ethereum',
    name: 'Test NFT',
    symbol: 'TEST',
    decimals: 0,
    totalSupply: '1000',
    deployedAt: new Date(),
    startBlock: 1000000,
    lastIndexedBlock: 2000000,
    metadata: {
      description: 'Test NFT Collection'
    }
  };

  describe('POST /api/v1/contracts', () => {
    it('should create a new contract successfully', async () => {
      const createStub = sandbox.stub(Contract, 'create').resolves({
        ...validContract,
        address: validContract.address.toLowerCase(),
        _id: new mongoose.Types.ObjectId(),
        toJSON: () => ({
          ...validContract,
          address: validContract.address.toLowerCase()
        })
      } as any);

      const res = await request(app)
        .post(`${API_PREFIX}/contracts`)
        .send(validContract);

      sinon.assert.calledOnce(createStub);
      expect(res.status).toBe(201);
      expect(res.body.address).toBe(validContract.address.toLowerCase());
      expect(res.body.type).toBe(validContract.type);
      expect(res.body.network).toBe(validContract.network);
    });

    it('should return 400 for invalid contract data', async () => {
      const invalidContract = {
        address: 'invalid-address',
        type: 'INVALID_TYPE',
        network: 'ethereum'
      };

      const res = await request(app)
        .post(`${API_PREFIX}/contracts`)
        .send(invalidContract);

      expect(res.status).toBe(400);
      expect(res.body.error).toBeDefined();
    });

    it('should return 409 for duplicate contract', async () => {
      const findOneStub = sandbox.stub(Contract, 'findOne').resolves(validContract);

      const res = await request(app)
        .post(`${API_PREFIX}/contracts`)
        .send(validContract);

      sinon.assert.calledOnce(findOneStub);
      expect(res.status).toBe(409);
      expect(res.body.error).toBeDefined();
    });
  });

  describe('GET /api/v1/contracts', () => {
    it('should return all contracts', async () => {
      const mockContracts = [{
        ...validContract,
        address: validContract.address.toLowerCase(),
        toJSON: () => ({
          ...validContract,
          address: validContract.address.toLowerCase()
        })
      }];
      
      // Create a query chain that matches how Mongoose actually works
      const queryChain = {
        skip: sandbox.stub().returnsThis(),
        limit: sandbox.stub().returnsThis(),
        sort: sandbox.stub().returnsThis(),
        lean: sandbox.stub().resolves(mockContracts)
      };
      
      const findStub = sandbox.stub(Contract, 'find').returns(queryChain as any);
      const countStub = sandbox.stub(Contract, 'countDocuments').resolves(1);

      const res = await request(app).get(`${API_PREFIX}/contracts`);

      expect(findStub.calledOnce).toBe(true);
      expect(queryChain.skip.calledOnce).toBe(true);
      expect(queryChain.limit.calledOnce).toBe(true);
      expect(queryChain.sort.calledOnce).toBe(true);
      expect(queryChain.lean.calledOnce).toBe(true);
      expect(res.status).toBe(200);
      expect(res.body.contracts).toBeDefined();
      expect(Array.isArray(res.body.contracts)).toBe(true);
      expect(res.body.contracts.length).toBe(1);
      expect(res.body.contracts[0].address).toBe(validContract.address.toLowerCase());
      expect(res.body.pagination).toBeDefined();
    });

    it('should filter contracts by network', async () => {
      const mockContracts = [{
        ...validContract,
        network: 'ethereum',
        toJSON: () => ({
          ...validContract,
          network: 'ethereum'
        })
      }];
      
      // Create a query chain that matches how Mongoose actually works
      const queryChain = {
        skip: sandbox.stub().returnsThis(),
        limit: sandbox.stub().returnsThis(),
        sort: sandbox.stub().returnsThis(),
        lean: sandbox.stub().resolves(mockContracts)
      };
      
      const findStub = sandbox.stub(Contract, 'find').returns(queryChain as any);
      const countStub = sandbox.stub(Contract, 'countDocuments').resolves(1);

      const res = await request(app)
        .get(`${API_PREFIX}/contracts`)
        .query({ network: 'ethereum' });

      expect(findStub.calledOnce).toBe(true);
      expect(queryChain.skip.calledOnce).toBe(true);
      expect(queryChain.limit.calledOnce).toBe(true);
      expect(queryChain.sort.calledOnce).toBe(true);
      expect(queryChain.lean.calledOnce).toBe(true);
      expect(res.status).toBe(200);
      expect(res.body.contracts).toBeDefined();
      expect(res.body.contracts.length).toBe(1);
      expect(res.body.contracts[0].network).toBe('ethereum');
    });

    it('should filter contracts by type', async () => {
      const mockContracts = [{
        ...validContract,
        type: ContractType.ERC721,
        toJSON: () => ({
          ...validContract,
          type: ContractType.ERC721
        })
      }];
      
      // Create a query chain that matches how Mongoose actually works
      const queryChain = {
        skip: sandbox.stub().returnsThis(),
        limit: sandbox.stub().returnsThis(),
        sort: sandbox.stub().returnsThis(),
        lean: sandbox.stub().resolves(mockContracts)
      };
      
      const findStub = sandbox.stub(Contract, 'find').returns(queryChain as any);
      const countStub = sandbox.stub(Contract, 'countDocuments').resolves(1);

      const res = await request(app)
        .get(`${API_PREFIX}/contracts`)
        .query({ type: ContractType.ERC721 });

      expect(findStub.calledOnce).toBe(true);
      expect(queryChain.skip.calledOnce).toBe(true);
      expect(queryChain.limit.calledOnce).toBe(true);
      expect(queryChain.sort.calledOnce).toBe(true);
      expect(queryChain.lean.calledOnce).toBe(true);
      expect(res.status).toBe(200);
      expect(res.body.contracts).toBeDefined();
      expect(res.body.contracts.length).toBe(1);
      expect(res.body.contracts[0].type).toBe(ContractType.ERC721);
    });

    it('should return empty array when no contracts match filters', async () => {
      const mockContracts: any[] = [];
      
      // Create a query chain that matches how Mongoose actually works
      const queryChain = {
        skip: sandbox.stub().returnsThis(),
        limit: sandbox.stub().returnsThis(),
        sort: sandbox.stub().returnsThis(),
        lean: sandbox.stub().resolves(mockContracts)
      };
      
      const findStub = sandbox.stub(Contract, 'find').returns(queryChain as any);
      const countStub = sandbox.stub(Contract, 'countDocuments').resolves(0);

      const res = await request(app)
        .get(`${API_PREFIX}/contracts`)
        .query({ network: 'nonexistent' });

      expect(findStub.calledOnce).toBe(true);
      expect(queryChain.skip.calledOnce).toBe(true);
      expect(queryChain.limit.calledOnce).toBe(true);
      expect(queryChain.sort.calledOnce).toBe(true);
      expect(queryChain.lean.calledOnce).toBe(true);
      expect(res.status).toBe(200);
      expect(res.body.contracts).toBeDefined();
      expect(res.body.contracts).toEqual([]);
      expect(res.body.pagination.totalItems).toBe(0);
    });
  });

  describe('GET /api/v1/contracts/:address', () => {
    it('should return contract by address', async () => {
      const findOneStub = sandbox.stub(Contract, 'findOne').resolves({
        ...validContract,
        address: validContract.address.toLowerCase(),
        toJSON: () => ({
          ...validContract,
          address: validContract.address.toLowerCase()
        })
      });

      const res = await request(app)
        .get(`${API_PREFIX}/contracts/${validContract.address}`);

      sinon.assert.calledWith(findOneStub, { address: validContract.address.toLowerCase() });
      expect(res.status).toBe(200);
      expect(res.body.address).toBe(validContract.address.toLowerCase());
      expect(res.body.type).toBe(validContract.type);
      expect(res.body.network).toBe(validContract.network);
    });

    it('should return 404 for non-existent contract', async () => {
      const findOneStub = sandbox.stub(Contract, 'findOne').resolves(null);

      const res = await request(app)
        .get(`${API_PREFIX}/contracts/0x1234567890123456789012345678901234567890`);

      sinon.assert.calledOnce(findOneStub);
      expect(res.status).toBe(404);
      expect(res.body.error).toBeDefined();
    });

    it('should return 400 for invalid address format', async () => {
      const res = await request(app)
        .get(`${API_PREFIX}/contracts/invalid-address`);

      expect(res.status).toBe(400);
      expect(res.body.error).toBeDefined();
    });
  });

  describe('PATCH /api/v1/contracts/:address', () => {
    it('should update contract fields', async () => {
      const updates = {
        name: 'Updated Token',
        symbol: 'UPDT',
        lastIndexedBlock: 3000000
      };

      const updatedContract = {
        ...validContract,
        ...updates,
        address: validContract.address.toLowerCase(),
        toJSON: () => ({
          ...validContract,
          ...updates,
          address: validContract.address.toLowerCase()
        })
      };

      const findOneAndUpdateStub = sandbox.stub(Contract, 'findOneAndUpdate').resolves(updatedContract);

      const res = await request(app)
        .patch(`${API_PREFIX}/contracts/${validContract.address}`)
        .send(updates);

      expect(findOneAndUpdateStub.calledOnce).toBe(true);
      expect(findOneAndUpdateStub.calledWith(
        { address: validContract.address.toLowerCase() },
        { $set: updates },
        { new: true, runValidators: true }
      )).toBe(true);
      expect(res.status).toBe(200);
      expect(res.body.name).toBe(updates.name);
      expect(res.body.symbol).toBe(updates.symbol);
      expect(res.body.lastIndexedBlock).toBe(updates.lastIndexedBlock);
    });

    it('should return 404 for non-existent contract', async () => {
      const findOneAndUpdateStub = sandbox.stub(Contract, 'findOneAndUpdate').resolves(null);

      const res = await request(app)
        .patch(`${API_PREFIX}/contracts/0x1234567890123456789012345678901234567890`)
        .send({ name: 'Updated Token' });

      expect(findOneAndUpdateStub.calledOnce).toBe(true);
      expect(res.status).toBe(404);
      expect(res.body.error).toBeDefined();
    });

    it('should return 400 for invalid update data', async () => {
      // Mock the validation middleware to reject invalid type
      const validateAddressStub = sandbox.stub().returns(true);
      sandbox.replace(require('../../../src/utils/validation'), 'validateAddress', validateAddressStub);

      const res = await request(app)
        .patch(`${API_PREFIX}/contracts/${validContract.address}`)
        .send({ type: 'INVALID_TYPE' });

      expect(res.status).toBe(400);
      expect(res.body.error).toBeDefined();
    });
  });

  describe('DELETE /api/v1/contracts/:address', () => {
    it('should delete contract', async () => {
      const deletedContract = {
        ...validContract,
        address: validContract.address.toLowerCase()
      };
      
      const findOneAndDeleteStub = sandbox.stub(Contract, 'findOneAndDelete').resolves(deletedContract);

      const res = await request(app)
        .delete(`${API_PREFIX}/contracts/${validContract.address}`);

      expect(findOneAndDeleteStub.calledOnce).toBe(true);
      expect(findOneAndDeleteStub.calledWith({ address: validContract.address.toLowerCase() })).toBe(true);
      expect(res.status).toBe(204);
    });

    it('should return 404 for non-existent contract', async () => {
      const findOneAndDeleteStub = sandbox.stub(Contract, 'findOneAndDelete').resolves(null);

      const res = await request(app)
        .delete(`${API_PREFIX}/contracts/0x1234567890123456789012345678901234567890`);

      expect(findOneAndDeleteStub.calledOnce).toBe(true);
      expect(res.status).toBe(404);
      expect(res.body.error).toBeDefined();
    });

    it('should return 400 for invalid address format', async () => {
      const res = await request(app)
        .delete(`${API_PREFIX}/contracts/invalid-address`);

      expect(res.status).toBe(400);
      expect(res.body.error).toBeDefined();
    });
  });
}); 