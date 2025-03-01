import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';

describe('Database Connection', () => {
  let mongoServer: MongoMemoryServer | null = null;

  beforeAll(async () => {
    // Close any existing connections
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    
    // Create new server
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    
    // Connect to the in-memory database
    await mongoose.connect(mongoUri, {
      autoIndex: true,
      autoCreate: true
    });
  }, 120000);

  afterAll(async () => {
    // Clean up
    if (mongoose.connection.readyState !== 0) {
      await mongoose.disconnect();
    }
    if (mongoServer) {
      await mongoServer.stop();
      mongoServer = null;
    }
    // Add a small delay to ensure all connections are properly closed
    await new Promise<void>((resolve) => setTimeout(() => resolve(), 1000));
  }, 120000);

  beforeEach(async () => {
    // Clear all collections before each test
    if (mongoose.connection.readyState === 1 && mongoose.connection.db) {
      const collections = await mongoose.connection.db.collections();
      for (const collection of collections) {
        await collection.deleteMany({});
      }
    }
  });

  it('should connect to the database successfully', async () => {
    expect(mongoose.connection.readyState).toBe(1);
  });

  it('should handle database operations', async () => {
    // Create a test model
    const TestSchema = new mongoose.Schema({
      name: String
    });
    
    // Use a unique model name to avoid conflicts
    const modelName = `Test_${Date.now()}`;
    const TestModel = mongoose.models[modelName] || mongoose.model(modelName, TestSchema);

    // Create a document
    const doc = await TestModel.create({ name: 'test' });
    expect(doc.name).toBe('test');

    // Find the document
    const found = await TestModel.findById(doc._id);
    expect(found?.name).toBe('test');

    // Update the document
    await TestModel.updateOne({ _id: doc._id }, { name: 'updated' });
    const updated = await TestModel.findById(doc._id);
    expect(updated?.name).toBe('updated');

    // Delete the document
    await TestModel.deleteOne({ _id: doc._id });
    const deleted = await TestModel.findById(doc._id);
    expect(deleted).toBeNull();
  });
}); 