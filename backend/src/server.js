'use strict';

const env = require('./config/env');
const { connect, disconnect } = require('./config/db');
const createApp = require('./app');
const Doctor = require('./models/Doctor');
const { seedDatabase } = require('./seed/seed');

/**
 * Convenience for the zero-setup demo: if we're on the ephemeral in-memory DB
 * (no MONGODB_URI) in a non-production env and it's empty, seed it on boot so
 * `npm run dev` is immediately usable. A real/persistent DB is never auto-seeded.
 */
async function maybeAutoSeed() {
  if (env.isProd || env.mongoUri) return;
  if ((await Doctor.estimatedDocumentCount()) > 0) return;
  console.log('[server] empty in-memory DB — auto-seeding demo data...');
  await seedDatabase();
  console.log(
    `[server] seeded. Login: ${env.seed.adminUser}/${env.seed.adminPass} (admin), ` +
      `${env.seed.receptionUser}/${env.seed.receptionPass} (reception).`
  );
}

async function start() {
  await connect();
  await maybeAutoSeed();
  const app = createApp();

  const server = app.listen(env.port, () => {
    console.log(`[server] Aarvy hospital API listening on http://localhost:${env.port}`);
    console.log(`[server] env=${env.nodeEnv}  clinicTz=${env.clinicTz}`);

    const { publicKey, privateKey, urlEndpoint } = env.imagekit;
    if (publicKey && privateKey && urlEndpoint) {
      console.log('[server] ImageKit: Configured and ready');
    } else {
      console.warn('[server] ImageKit: WARNING - Credentials not configured. Doctor photo uploads will fail.');
    }
  });

  const shutdown = async (signal) => {
    console.log(`\n[server] ${signal} received — shutting down...`);
    server.close(async () => {
      await disconnect();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

start().catch((err) => {
  console.error('[server] failed to start:', err);
  process.exit(1);
});
