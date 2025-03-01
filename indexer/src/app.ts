import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import mongoose from 'mongoose';
import contractRoutes from './routes/contracts';
import { errorHandler } from './middleware/error-handler';
import { securityMiddleware } from './middleware/security';

const app = express();

// Security middleware
app.use(helmet());
app.use(cors());
app.use(securityMiddleware);

// Body parsing middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// API Routes
app.use('/api/v1/contracts', contractRoutes);

// Error handling middleware
app.use(errorHandler);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not found' });
});

export { app }; 