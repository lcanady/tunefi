import { afterAll, beforeAll, jest } from '@jest/globals';
import sinon from 'sinon';
import mongoose from 'mongoose';

// Extend the timeout for all tests
jest.setTimeout(30000);

let sandbox: sinon.SinonSandbox;

// Global setup before all tests
beforeAll(() => {
  process.env.NODE_ENV = 'test';
  
  // Create a sinon sandbox for global stubs
  sandbox = sinon.createSandbox();
  
  // Stub mongoose connection for all tests
  sandbox.stub(mongoose, 'connection').value({
    readyState: 1,
    db: {
      collections: async () => []
    }
  });
});

// Global cleanup after all tests
afterAll(() => {
  sandbox.restore();
}); 