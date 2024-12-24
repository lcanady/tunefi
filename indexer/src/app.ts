import express from 'express';
import { version } from '../package.json';
import { errorHandler } from './middleware/error-handler';

// Create Express app
const app = express();

// Add JSON parsing middleware
app.use(express.json());

// Health check endpoint
app.get('/api/v1/indexer/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version,
    uptime: process.uptime(),
  });
});

// Add error handling middleware last
app.use(errorHandler);

export { app }; 