import { Request, Response } from 'express';
import { ValidationError, errorHandler } from '../../../src/middleware/error-handler';
import mongoose from 'mongoose';

describe('Error Handler Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let nextFunction: jest.Mock;

  beforeEach(() => {
    mockRequest = {};
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn()
    };
    nextFunction = jest.fn();
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
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid input' });
  });

  it('should handle mongoose ValidationError', () => {
    const error = new mongoose.Error.ValidationError();
    error.message = 'Mongoose validation failed';

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(400);
    expect(mockResponse.json).toHaveBeenCalledWith({
      error: 'Validation failed',
      details: {}
    });
  });

  it('should handle mongoose CastError', () => {
    const error = new mongoose.Error.CastError('type', 'value', 'path');

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(400);
    expect(mockResponse.json).toHaveBeenCalledWith({
      error: 'Invalid data format',
      details: {
        path: 'path',
        value: 'value',
        type: 'type'
      }
    });
  });

  it('should handle duplicate key error', () => {
    const error = new Error('Duplicate key') as any;
    error.name = 'MongoError';
    error.code = 11000;

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(409);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Duplicate entry' });
  });

  it('should handle unknown errors', () => {
    const error = new Error('Unknown error');

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Unknown error' });
  });

  it('should log errors', () => {
    const consoleSpy = jest.spyOn(console, 'error').mockImplementation();
    const error = new Error('Test error');

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(consoleSpy).toHaveBeenCalledWith(error);
    consoleSpy.mockRestore();
  });

  it('should handle mongoose ValidationError with multiple validation errors', () => {
    const error = new mongoose.Error.ValidationError();
    error.errors = {
      field1: new mongoose.Error.ValidatorError({ message: 'Field1 error' }),
      field2: new mongoose.Error.ValidatorError({ message: 'Field2 error' })
    };

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(400);
    expect(mockResponse.json).toHaveBeenCalledWith({
      error: 'Validation failed',
      details: {
        field1: 'Field1 error',
        field2: 'Field2 error'
      }
    });
  });

  it('should handle mongoose CastError with detailed path information', () => {
    const error = new mongoose.Error.CastError('ObjectId', 'invalidid', 'userId');
    error.message = 'Cast to ObjectId failed for value "invalidid" at path "userId"';

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(400);
    expect(mockResponse.json).toHaveBeenCalledWith({
      error: 'Invalid data format',
      details: {
        path: 'userId',
        value: 'invalidid',
        type: 'ObjectId'
      }
    });
  });

  it('should handle errors with custom status codes', () => {
    const error = new Error('Custom error') as any;
    error.statusCode = 418;

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(418);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Custom error' });
  });

  it('should handle errors with additional metadata', () => {
    const error = new Error('Error with metadata') as any;
    error.metadata = {
      code: 'CUSTOM_ERROR',
      timestamp: new Date().toISOString(),
      details: {
        reason: 'Something went wrong',
        suggestion: 'Try again later'
      }
    };

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.json).toHaveBeenCalledWith({
      error: 'Error with metadata',
      metadata: error.metadata
    });
  });

  it('should handle null or undefined errors', () => {
    errorHandler(
      null as any,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Unknown error occurred' });

    errorHandler(
      undefined as any,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Unknown error occurred' });
  });

  it('should handle errors with circular references', () => {
    const error = new Error('Circular error') as any;
    error.circular = error;

    errorHandler(
      error,
      mockRequest as Request,
      mockResponse as Response,
      nextFunction
    );

    expect(mockResponse.status).toHaveBeenCalledWith(500);
    expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Circular error' });
  });

  afterEach(() => {
    jest.clearAllMocks();
  });
}); 