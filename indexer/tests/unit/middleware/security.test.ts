import { Request, Response, NextFunction } from 'express';
import { rateLimiter, corsMiddleware, resetRateLimitStore } from '../../../src/middleware/security';

describe('Security Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction;

  beforeEach(() => {
    mockRequest = {
      method: 'GET',
      headers: {},
      ip: '127.0.0.1'
    };
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
      setHeader: jest.fn().mockReturnThis(),
      header: jest.fn().mockReturnThis()
    };
    nextFunction = jest.fn();
  });

  describe('CORS Middleware', () => {
    it('should set CORS headers for allowed origin', () => {
      const allowedOrigin = 'http://localhost:3000';
      mockRequest.headers!.origin = allowedOrigin;
      process.env.ALLOWED_ORIGINS = allowedOrigin;

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.setHeader).toHaveBeenCalledWith('Access-Control-Allow-Origin', allowedOrigin);
      expect(mockResponse.setHeader).toHaveBeenCalledWith('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
      expect(nextFunction).toHaveBeenCalled();
    });

    it('should handle preflight requests', () => {
      mockRequest.method = 'OPTIONS';
      mockRequest.headers!.origin = 'http://localhost:3000';
      process.env.ALLOWED_ORIGINS = 'http://localhost:3000';

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.setHeader).toHaveBeenCalledWith('Access-Control-Allow-Headers', 'Content-Type, Authorization');
      expect(mockResponse.setHeader).toHaveBeenCalledWith('Access-Control-Max-Age', '86400');
      expect(nextFunction).toHaveBeenCalled();
    });

    it('should block requests from unauthorized origins', () => {
      mockRequest.headers!.origin = 'http://malicious-site.com';
      process.env.ALLOWED_ORIGINS = 'http://localhost:3000';

      corsMiddleware(mockRequest as Request, mockResponse as Response, nextFunction);

      expect(mockResponse.status).toHaveBeenCalledWith(403);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Origin not allowed' });
      expect(nextFunction).not.toHaveBeenCalled();
    });
  });

  describe('Rate Limiter', () => {
    beforeEach(() => {
      jest.useFakeTimers();
      resetRateLimitStore();
      jest.clearAllMocks();
    });

    afterEach(() => {
      jest.useRealTimers();
      resetRateLimitStore();
    });

    it('should allow requests within rate limit', () => {
      // First request starts at count 1
      rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalledTimes(1);

      // Make 98 more requests (total 99)
      for (let i = 0; i < 98; i++) {
        rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      }

      expect(nextFunction).toHaveBeenCalledTimes(99);
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('should block requests exceeding rate limit', () => {
      // Make 100 requests (reaching the limit)
      for (let i = 0; i < 100; i++) {
        rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      }
      expect(nextFunction).toHaveBeenCalledTimes(100);

      // Next request should be blocked
      rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalledTimes(100);
      expect(mockResponse.status).toHaveBeenCalledWith(429);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Too many requests' });
    });

    it('should reset rate limit after window expires', () => {
      // Make 100 requests (reaching the limit)
      for (let i = 0; i < 100; i++) {
        rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      }
      expect(nextFunction).toHaveBeenCalledTimes(100);

      // Next request should be blocked
      rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalledTimes(100);
      expect(mockResponse.status).toHaveBeenCalledWith(429);

      // Move time forward by rate limit window
      jest.advanceTimersByTime(60 * 1000); // 1 minute

      // Reset mocks to check new calls
      jest.clearAllMocks();

      // First request after reset should work
      rateLimiter(mockRequest as Request, mockResponse as Response, nextFunction);
      expect(nextFunction).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalled();
    });
  });
}); 