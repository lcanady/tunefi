import { Request, Response, NextFunction } from 'express';
import { 
  corsMiddleware, 
  rateLimiter,
  securityHeaders,
  createRateLimiter
} from '../../../src/middleware/security';

type MockRequest = {
  method: string;
  headers: Record<string, string | undefined>;
  ip: string;
  connection: {
    remoteAddress: string;
  };
  app: {
    get: (key: string) => boolean;
  };
};

describe('Security Middleware', () => {
  let mockRequest: MockRequest;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction = jest.fn();

  beforeEach(() => {
    mockRequest = {
      method: 'GET',
      headers: {},
      ip: '127.0.0.1',
      app: {
        get: () => false
      },
      connection: {
        remoteAddress: '127.0.0.1'
      }
    };
    mockResponse = {
      setHeader: jest.fn().mockReturnThis(),
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      header: jest.fn().mockReturnThis()
    };
    nextFunction = jest.fn();
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('CORS Middleware', () => {
    it('should set CORS headers for allowed origins', () => {
      process.env.ALLOWED_ORIGINS = 'http://localhost:3000,https://app.example.com';
      mockRequest.headers!.origin = 'http://localhost:3000';

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Access-Control-Allow-Origin',
        'http://localhost:3000'
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Access-Control-Allow-Methods',
        'GET,HEAD,PUT,PATCH,POST,DELETE'
      );
      expect(nextFunction).toHaveBeenCalled();
    });

    it('should handle preflight requests', () => {
      mockRequest.method = 'OPTIONS';
      mockRequest.headers!.origin = 'http://localhost:3000';

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Access-Control-Allow-Headers',
        'Content-Type,Authorization'
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Access-Control-Max-Age',
        '86400'
      );
      expect(nextFunction).toHaveBeenCalled();
    });

    it('should block requests from unauthorized origins', () => {
      process.env.ALLOWED_ORIGINS = 'http://localhost:3000';
      mockRequest.headers!.origin = 'http://malicious.com';

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(403);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Forbidden',
        message: 'Origin not allowed'
      });
      expect(nextFunction).not.toHaveBeenCalled();
    });
  });

  describe('Rate Limiter', () => {
    it('should allow requests within rate limit', async () => {
      await rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();
    });

    it('should block requests exceeding rate limit', async () => {
      const testLimiter = createRateLimiter({
        windowMs: 15 * 60 * 1000,
        max: 1
      });

      // First request should pass
      await testLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();

      // Second request should be blocked
      await testLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(mockResponse.status).toHaveBeenCalledWith(429);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Too Many Requests',
        message: 'Rate limit exceeded'
      });
    });

    it('should track rate limits per IP', async () => {
      const testLimiter = createRateLimiter({
        windowMs: 15 * 60 * 1000,
        max: 1
      });

      // First request with first IP
      const request1 = {
        ...mockRequest,
        ip: '127.0.0.1',
        connection: { remoteAddress: '127.0.0.1' }
      };
      await testLimiter(request1 as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();

      // Second request with different IP
      const request2 = {
        ...mockRequest,
        ip: '127.0.0.2',
        connection: { remoteAddress: '127.0.0.2' }
      };
      await testLimiter(request2 as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalledTimes(2);
    });
  });

  describe('Security Headers', () => {
    it('should set security headers', () => {
      securityHeaders(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'X-Content-Type-Options',
        'nosniff'
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'X-Frame-Options',
        'DENY'
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'X-XSS-Protection',
        '1; mode=block'
      );
      expect(mockResponse.setHeader).toHaveBeenCalledWith(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains'
      );
      expect(nextFunction).toHaveBeenCalled();
    });
  });
}); 