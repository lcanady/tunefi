import rateLimit from 'express-rate-limit';
import cors from 'cors';
import helmet from 'helmet';

// Rate limiter configuration
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});

// CORS configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};

// Combine all security middleware
export const securityMiddleware = [
  // Rate limiting
  limiter,
  
  // CORS
  cors(corsOptions),
  
  // Security headers
  helmet(),
  
  // XSS protection
  helmet.xssFilter(),
  
  // Prevent clickjacking
  helmet.frameguard({ action: 'deny' }),
  
  // Disable MIME type sniffing
  helmet.noSniff(),
  
  // Hide X-Powered-By header
  helmet.hidePoweredBy(),
  
  // HTTP Strict Transport Security
  helmet.hsts({
    maxAge: 31536000, // 1 year
    includeSubDomains: true,
    preload: true
  })
]; 