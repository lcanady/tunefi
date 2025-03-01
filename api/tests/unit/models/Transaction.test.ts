import mongoose from 'mongoose';
import { Transaction, ITransaction } from '../../../src/models/Transaction';
import { Contract, ContractType } from '../../../src/models/Contract';

describe('Transaction Model', () => {
  let contractId: mongoose.Types.ObjectId;

  beforeAll(async () => {
    // Create a contract to reference
    const contract = await Contract.create({
      address: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
      type: ContractType.ERC721,
      network: 'ethereum',
      name: 'Test NFT',
      isVerified: false
    });
    contractId = contract._id as mongoose.Types.ObjectId;
  });

  const validTransaction = {
    contract: undefined as unknown as mongoose.Types.ObjectId, // Will be set in beforeEach
    hash: '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
    blockNumber: 1000000,
    from: '0x742d35Cc6634C0532925a3b844Bc454e4438f44e',
    to: '0x742d35Cc6634C0532925a3b844Bc454e4438f44f',
    value: '1000000000000000000',
    gasUsed: 21000,
    gasPrice: '20000000000',
    input: '0x',
    status: true,
    timestamp: Date.now()
  };

  beforeEach(() => {
    // Set the contract ID before each test
    validTransaction.contract = contractId;
  });

  afterAll(async () => {
    // Clean up
    await Contract.deleteMany({});
    await Transaction.deleteMany({});
  });

  it('should create a transaction successfully', async () => {
    const transaction = await Transaction.create(validTransaction);
    expect(transaction.hash).toBe(validTransaction.hash.toLowerCase());
    expect(transaction.blockNumber).toBe(validTransaction.blockNumber);
    expect(transaction.from).toBe(validTransaction.from.toLowerCase());
    expect(transaction.to).toBe(validTransaction.to.toLowerCase());
    expect(transaction.value).toBe(validTransaction.value);
    expect(transaction.gasUsed).toBe(validTransaction.gasUsed);
    expect(transaction.gasPrice).toBe(validTransaction.gasPrice);
    expect(transaction.input).toBe(validTransaction.input);
    expect(transaction.status).toBe(validTransaction.status);
    expect(transaction.timestamp).toEqual(validTransaction.timestamp);
    expect(transaction.contract).toEqual(contractId);
  });

  it('should require all mandatory fields', async () => {
    const invalidTransaction = {};
    await expect(Transaction.create(invalidTransaction)).rejects.toThrow();
  });

  it('should enforce unique hash', async () => {
    await Transaction.create(validTransaction);
    await expect(Transaction.create(validTransaction)).rejects.toThrow();
  });

  it('should allow different hashes', async () => {
    await Transaction.create(validTransaction);
    const differentHash = { 
      ...validTransaction, 
      hash: '0x2234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
    };
    await expect(Transaction.create(differentHash)).resolves.toBeDefined();
  });

  it('should convert addresses and hash to lowercase', async () => {
    const upperCaseTransaction = {
      ...validTransaction,
      hash: '0x1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF', // Valid format but uppercase
      from: validTransaction.from.toUpperCase(),
      to: validTransaction.to.toUpperCase()
    };
    const transaction = await Transaction.create(upperCaseTransaction);
    expect(transaction.hash).toBe(upperCaseTransaction.hash.toLowerCase());
    expect(transaction.from).toBe(upperCaseTransaction.from.toLowerCase());
    expect(transaction.to).toBe(upperCaseTransaction.to.toLowerCase());
  });
}); 