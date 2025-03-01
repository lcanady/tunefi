import request from 'supertest';
import { app } from '../../src/app';

describe('Swagger Documentation', () => {
  const API_PREFIX = '/api/v1';

  it('should serve the Swagger documentation', async () => {
    const response = await request(app)
      .get(`${API_PREFIX}/docs/`)
      .expect(200);
    
    expect(response.text).toContain('swagger-ui');
  });

  it('should serve the Swagger JSON', async () => {
    const response = await request(app)
      .get(`${API_PREFIX}/docs/swagger-ui-init.js`)
      .expect(200);
    
    expect(response.text).toContain('swagger');
  });
});