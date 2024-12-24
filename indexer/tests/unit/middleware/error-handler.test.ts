import { Request, Response, NextFunction } from 'express';
import { 
  errorHandler, 
  NotFoundError, 
  ValidationError, 
  UnauthorizedError, 
  ForbiddenError,
  BaseError 
} from '../../../src/middleware/error-handler';

describe('Error Handler Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: NextFunction = jest.fn();

  beforeEach(() => {
    mockRequest = {};
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    process.env.NODE_ENV = 'production';
  });

  afterEach(() => {
    delete process.env.NODE_ENV;
  });

  describe('BaseError', () => {
    it('should create error with default status code', () => {
      const error = new BaseError('Test error');
      expect(error.statusCode).toBe(500);
      expect(error.status).toBe('error');
    });

    it('should create error with custom status code', () => {
      const error = new BaseError('Test error', 400);
      expect(error.statusCode).toBe(400);
      expect(error.status).toBe('fail');
    });

    it('should capture stack trace', () => {
      const error = new BaseError('Test error');
      expect(error.stack).toBeDefined();
    });
  });

  describe('Error Classes', () => {
    it('should create NotFoundError with default message', () => {
      const error = new NotFoundError();
      expect(error.message).toBe('Resource not found');
      expect(error.statusCode).toBe(404);
    });

    it('should create ValidationError with default message', () => {
      const error = new ValidationError();
      expect(error.message).toBe('Invalid input');
      expect(error.statusCode).toBe(400);
    });

    it('should create UnauthorizedError with default message', () => {
      const error = new UnauthorizedError();
      expect(error.message).toBe('Unauthorized access');
      expect(error.statusCode).toBe(401);
    });

    it('should create ForbiddenError with default message', () => {
      const error = new ForbiddenError();
      expect(error.message).toBe('Forbidden access');
      expect(error.statusCode).toBe(403);
    });
  });

  describe('Error Handler', () => {
    it('should handle NotFoundError', () => {
      const error = new NotFoundError('Resource not found');
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Not Found',
        message: 'Resource not found',
        statusCode: 404,
      });
    });

    it('should handle ValidationError', () => {
      const error = new ValidationError('Invalid input');
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Bad Request',
        message: 'Invalid input',
        statusCode: 400,
      });
    });

    it('should handle UnauthorizedError', () => {
      const error = new UnauthorizedError('Invalid token');
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Unauthorized',
        message: 'Invalid token',
        statusCode: 401,
      });
    });

    it('should handle ForbiddenError', () => {
      const error = new ForbiddenError('Access denied');
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(403);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Forbidden',
        message: 'Access denied',
        statusCode: 403,
      });
    });

    it('should handle unknown errors', () => {
      const error = new Error('Something went wrong');
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Internal Server Error',
        message: 'Something went wrong',
        statusCode: 500,
      });
    });

    it('should handle errors with custom status codes', () => {
      const error = new Error('Custom error');
      (error as any).statusCode = 403;
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(403);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Forbidden',
        message: 'Custom error',
        statusCode: 403,
      });
    });

    it('should include stack trace in development environment', () => {
      process.env.NODE_ENV = 'development';
      const error = new Error('Development error');
      error.stack = 'Error stack trace';
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Internal Server Error',
        message: 'Development error',
        statusCode: 500,
        stack: 'Error stack trace'
      });
    });

    it('should handle service unavailable error', () => {
      const error = new BaseError('Service unavailable', 503);
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(503);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Service Unavailable',
        message: 'Service unavailable',
        statusCode: 503,
      });
    });

    it('should handle bad gateway error', () => {
      const error = new BaseError('Bad gateway', 502);
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(502);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Bad Gateway',
        message: 'Bad gateway',
        statusCode: 502,
      });
    });

    it('should handle unknown status codes', () => {
      const error = new BaseError('Unknown error', 599);
      
      errorHandler(
        error,
        mockRequest as Request,
        mockResponse as Response,
        nextFunction
      );

      expect(mockResponse.status).toHaveBeenCalledWith(599);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Internal Server Error',
        message: 'Unknown error',
        statusCode: 599,
      });
    });
  });
}); 