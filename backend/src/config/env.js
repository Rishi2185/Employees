'use strict';

const path = require('path');

// Load .env from the backend root explicitly, NOT from process.cwd(). Under pm2
// the process is often launched from a parent dir (e.g. ~/Employees), so a
// bare dotenv.config() would look for ~/Employees/.env and silently find
// nothing — leaving IMAGEKIT_* (and everything else) blank at runtime.
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

/** Parse a comma-separated origins list; '*' means allow all. */
function parseOrigins(raw) {
  if (!raw || raw.trim() === '' || raw.trim() === '*') return '*';
  return raw
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);
}

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT || '4000', 10),

  // Blank => in-memory MongoDB (see config/db.js).
  mongoUri: process.env.MONGODB_URI || '',

  clinicTz: process.env.CLINIC_TZ || 'Asia/Kolkata',

  jwtSecret: process.env.JWT_SECRET || 'dev-insecure-secret-change-me',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '12h',
  bcryptRounds: parseInt(process.env.BCRYPT_ROUNDS || '12', 10),

  corsOrigins: parseOrigins(process.env.CORS_ORIGINS),

  seed: {
    adminUser: process.env.ADMIN_USER || 'admin',
    adminPass: process.env.ADMIN_PASS || 'admin1234',
    receptionUser: process.env.RECEPTION_USER || 'reception',
    receptionPass: process.env.RECEPTION_PASS || 'reception1234',
  },

  imagekit: {
    publicKey: process.env.IMAGEKIT_PUBLIC_KEY || '',
    privateKey: process.env.IMAGEKIT_PRIVATE_KEY || '',
    urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT || '',
  },
};

env.isProd = env.nodeEnv === 'production';
env.isTest = env.nodeEnv === 'test';

// Fail fast in production if the JWT secret was never set.
if (env.isProd && env.jwtSecret === 'dev-insecure-secret-change-me') {
  throw new Error('JWT_SECRET must be set in production.');
}

module.exports = env;
