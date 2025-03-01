import { Request, Response, NextFunction } from 'express';
import { Error as MongooseError } from 'mongoose';

export const errorHandler = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(err);

  // Handle null/undefined errors
  if (!err) {
    return res.status(500).json({
      error: 'An unknown error occurred'
    });
  }

  // Handle validation errors
  if (err instanceof MongooseError.ValidationError) {
    const errors = Object.values(err.errors).map(error => error.message);
    return res.status(400).json({
      error: 'Validation failed',
      details: errors
    });
  }

  // Handle cast errors (invalid ObjectId, etc.)
  if (err instanceof MongooseError.CastError) {
    return res.status(400).json({
      error: 'Invalid data format',
      details: err.message
    });
  }

  // Handle duplicate key errors
  if (err.code === 11000) {
    return res.status(409).json({
      error: 'Duplicate entry',
      details: err.message
    });
  }

  // Handle errors with custom status codes
  if (err.statusCode) {
    return res.status(err.statusCode).json({
      error: err.message
    });
  }

  // Handle errors with additional metadata
  if (err.metadata) {
    return res.status(500).json({
      error: err.message,
      metadata: err.metadata
    });
  }

  // Default error response
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
}; 