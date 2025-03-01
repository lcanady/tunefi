import express from 'express';
import mongoose from 'mongoose';
import contractRoutes from './routes/contracts';
import { securityMiddleware } from './middleware/security';
import { errorHandler } from './middleware/error-handler';

const app = express();

// Apply security middleware
app.use(securityMiddleware);

// Parse JSON bodies
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Routes
app.use('/contracts', contractRoutes);

// Error handling
app.use(errorHandler);

export { app }; 