import { Request, Response, NextFunction } from 'express';
import rateLimit, { Options } from 'express-rate-limit';
import { logger } from '../utils/logger';

// CORS middleware
export const corsMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',') || [];
  const origin = req.headers.origin;

  if (!origin || allowedOrigins.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin || '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET,HEAD,PUT,PATCH,POST,DELETE');
    
    if (req.method === 'OPTIONS') {
      res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization');
      res.setHeader('Access-Control-Max-Age', '86400'); // 24 hours
    }
    
    next();
  } else {
    logger.warn(`Blocked request from unauthorized origin: ${origin}`);
    res.status(403).json({
      error: 'Forbidden',
      message: 'Origin not allowed'
    });
  }
};

// Rate limiting middleware factory
export const createRateLimiter = (options?: Partial<Options>) => {
  return rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // Limit each IP to 100 requests per windowMs
    message: {
      error: 'Too Many Requests',
      message: 'Rate limit exceeded'
    },
    standardHeaders: true,
    legacyHeaders: false,
    handler: (req: Request, res: Response) => {
      logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
      res.status(429).json({
        error: 'Too Many Requests',
        message: 'Rate limit exceeded'
      });
    },
    ...options
  });
};

// Default rate limiter instance
export const rateLimiter = createRateLimiter();

// Security headers middleware
export const securityHeaders = (req: Request, res: Response, next: NextFunction) => {
  // Prevent MIME type sniffing
  res.setHeader('X-Content-Type-Options', 'nosniff');
  
  // Prevent clickjacking
  res.setHeader('X-Frame-Options', 'DENY');
  
  // Enable XSS filter
  res.setHeader('X-XSS-Protection', '1; mode=block');
  
  // Enable HSTS
  res.setHeader(
    'Strict-Transport-Security',
    'max-age=31536000; includeSubDomains'
  );
  
  next();
}; 