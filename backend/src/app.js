'use strict';

const express = require('express');
const helmet = require('helmet');
const cors = require('cors');

const env = require('./config/env');
const { globalLimiter } = require('./middleware/rateLimiters');
const { notFoundHandler, errorHandler } = require('./middleware/errorHandler');

const healthRoutes = require('./routes/health');
const authRoutes = require('./routes/auth');
const doctorRoutes = require('./routes/doctors');
const appointmentRoutes = require('./routes/appointments');
const statsRoutes = require('./routes/stats');
const summaryRoutes = require('./routes/summaries');
const metaRoutes = require('./routes/meta');
const imagekitAuthRoutes = require('./routes/imagekitAuth');

/** Build the Express app (no DB connection / no listen — that's server.js). */
function createApp() {
  const app = express();

  app.set('trust proxy', 1);
  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigins, // '*' or explicit allowlist
      credentials: env.corsOrigins !== '*',
    })
  );
  app.use(express.json({ limit: '256kb' }));
  app.use(globalLimiter);

  app.use('/api/health', healthRoutes);
  app.use('/api/auth', authRoutes);
  app.use('/api/doctors', doctorRoutes);
  app.use('/api/appointments', appointmentRoutes);
  app.use('/api/stats', statsRoutes);
  app.use('/api/summaries', summaryRoutes);
  app.use('/api', metaRoutes); // /api/specialties, /api/hospitals
  app.use('/api/imagekit', imagekitAuthRoutes);

  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

module.exports = createApp;
