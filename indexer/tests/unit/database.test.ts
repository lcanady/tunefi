import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { connectDatabase, closeDatabase } from '../../src/config/database';

jest.setTimeout(30000);

describe('Database Connection', () => {
  let mongoServer: MongoMemoryServer;

  beforeAll(async () => {
    await mongoose.disconnect();
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    process.env.MONGODB_URI = mongoUri;
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
    await new Promise<void>((resolve) => setTimeout(() => resolve(), 1000));
  });

  beforeEach(async () => {
    if (mongoose.connection.readyState !== 1) {
      await connectDatabase();
    }
    const collections = await mongoose.connection.db?.collections();
    if (collections) {
      await Promise.all(collections.map(collection => collection.deleteMany({})));
    }
  });

  afterEach(async () => {
    await mongoose.disconnect();
  });

  it('should connect to the database successfully', async () => {
    await connectDatabase();
    expect(mongoose.connection.readyState).toBe(1);
  });

  it('should handle connection errors gracefully', async () => {
    const originalUri = process.env.MONGODB_URI;
    process.env.MONGODB_URI = 'mongodb://invalid:27017/test';
    await expect(connectDatabase()).rejects.toThrow();
    process.env.MONGODB_URI = originalUri;
  });

  it('should close database connection successfully', async () => {
    await connectDatabase();
    await closeDatabase();
    expect(mongoose.connection.readyState).toBe(0);
  });

  it('should handle database operations', async () => {
    await connectDatabase();
    const TestModel = mongoose.models.Test || mongoose.model('Test', new mongoose.Schema({
      test: String
    }));

    const testDoc = await TestModel.create({ test: 'data' });
    expect(testDoc).toBeDefined();
    expect(testDoc.test).toBe('data');

    const foundDoc = await TestModel.findOne({ test: 'data' });
    expect(foundDoc).toBeDefined();
    expect(foundDoc?.test).toBe('data');
  });
}); 