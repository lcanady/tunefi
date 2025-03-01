import mongoose from 'mongoose';
import { Contract, ContractType, IContract } from '../../../src/models/Contract';

describe('Contract Model', () => {
  const validContract = {
    address: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    type: ContractType.ERC721,
    network: 'ethereum',
    name: 'Test NFT',
    symbol: 'TEST',
    isVerified: false,
    deployedAt: Date.now(),
    lastIndexedBlock: 2000000
  };

  it('should create a contract successfully', async () => {
    const contract = await Contract.create(validContract);
    expect(contract.address).toBe(validContract.address.toLowerCase());
    expect(contract.type).toBe(validContract.type);
    expect(contract.network).toBe(validContract.network);
    expect(contract.name).toBe(validContract.name);
    expect(contract.symbol).toBe(validContract.symbol);
    expect(contract.deployedAt).toEqual(validContract.deployedAt);
    expect(contract.lastIndexedBlock).toBe(validContract.lastIndexedBlock);
  });

  it('should require address, type, and network', async () => {
    const invalidContract = {};
    await expect(Contract.create(invalidContract)).rejects.toThrow();
  });

  it('should enforce unique address per network', async () => {
    await Contract.create(validContract);
    await expect(Contract.create(validContract)).rejects.toThrow();
  });

  it('should allow different addresses on different networks', async () => {
    await Contract.create(validContract);
    const differentAddress = { 
      ...validContract, 
      network: 'polygon',
      address: '0x842d35Cc6634C0532925a3b844Bc454e4438f44f' // Different address
    };
    await expect(Contract.create(differentAddress)).resolves.toBeDefined();
  });

  it('should convert address to lowercase', async () => {
    const upperCaseAddress = {
      ...validContract,
      address: '0x742D35CC6634C0532925A3B844BC454E4438F44E'
    };
    const contract = await Contract.create(upperCaseAddress);
    expect(contract.address).toBe(upperCaseAddress.address.toLowerCase());
  });

  it('should validate contract type', async () => {
    const invalidType = {
      ...validContract,
      type: 'INVALID_TYPE'
    };
    await expect(Contract.create(invalidType)).rejects.toThrow();
  });

  it('should update contract fields', async () => {
    const contract = await Contract.create(validContract);
    const newBlockNumber = 3000000;
    contract.lastIndexedBlock = newBlockNumber;
    await contract.save();

    const updatedContract = await Contract.findById(contract._id);
    expect(updatedContract?.lastIndexedBlock).toBe(newBlockNumber);
  });
}); 