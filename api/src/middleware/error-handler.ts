import { Request, Response, NextFunction } from 'express';
import mongoose from 'mongoose';

export class ValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ValidationError';
  }
}

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  console.error(err);

  // Handle null/undefined errors
  if (!err) {
    return res.status(500).json({ error: 'Unknown error occurred' });
  }

  // Handle custom validation errors
  if (err instanceof ValidationError) {
    return res.status(400).json({ error: err.message });
  }

  // Handle mongoose validation errors with details
  if (err instanceof mongoose.Error.ValidationError) {
    const details: { [key: string]: string } = {};
    for (const field in err.errors) {
      details[field] = err.errors[field].message;
    }
    return res.status(400).json({
      error: 'Validation failed',
      details
    });
  }

  // Handle mongoose cast errors with details
  if (err instanceof mongoose.Error.CastError) {
    return res.status(400).json({
      error: 'Invalid data format',
      details: {
        path: err.path,
        value: err.value,
        type: err.kind
      }
    });
  }

  // Handle duplicate key errors
  if (err.name === 'MongoError' && (err as any).code === 11000) {
    return res.status(409).json({ error: 'Duplicate entry' });
  }

  // Handle custom status codes
  if ((err as any).statusCode) {
    return res.status((err as any).statusCode).json({ error: err.message });
  }

  // Handle errors with metadata
  if ((err as any).metadata) {
    return res.status(500).json({
      error: err.message,
      metadata: (err as any).metadata
    });
  }

  // Handle all other errors
  return res.status(500).json({ error: err.message || 'Internal server error' });
}; 