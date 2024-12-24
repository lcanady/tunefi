import { Request, Response, NextFunction } from 'express';

export class BaseError extends Error {
  statusCode: number;
  status: string;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.status = `${statusCode}`.startsWith('4') ? 'fail' : 'error';
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends BaseError {
  constructor(message: string = 'Resource not found') {
    super(message, 404);
  }
}

export class ValidationError extends BaseError {
  constructor(message: string = 'Invalid input') {
    super(message, 400);
  }
}

export class UnauthorizedError extends BaseError {
  constructor(message: string = 'Unauthorized access') {
    super(message, 401);
  }
}

export class ForbiddenError extends BaseError {
  constructor(message: string = 'Forbidden access') {
    super(message, 403);
  }
}

const getErrorName = (statusCode: number): string => {
  const errorNames: { [key: number]: string } = {
    400: 'Bad Request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Not Found',
    500: 'Internal Server Error',
    502: 'Bad Gateway',
    503: 'Service Unavailable'
  };
  return errorNames[statusCode] || 'Internal Server Error';
};

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const statusCode = (err as any).statusCode || 500;
  const errorName = getErrorName(statusCode);

  res.status(statusCode).json({
    error: errorName,
    message: err.message,
    statusCode,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
}; 