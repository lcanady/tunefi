import request from 'supertest';
import { app } from '../../src/app';

describe('Health Check Endpoint', () => {
  it('should return 200 OK with status information', async () => {
    const response = await request(app)
      .get('/api/v1/indexer/health')
      .expect('Content-Type', /json/)
      .expect(200);

    expect(response.body).toEqual({
      status: 'ok',
      timestamp: expect.any(String),
      version: expect.any(String),
      uptime: expect.any(Number),
    });
  });
}); 