'use strict';

const mongoose = require('mongoose');
const env = require('./env');

let memoryServer = null;

mongoose.set('strictQuery', true);

/**
 * Connect Mongoose to MongoDB.
 *
 * Resolution order:
 *   1. If MONGODB_URI is set (local mongod or Atlas), use it.
 *   2. Otherwise spin up an in-memory MongoDB (mongodb-memory-server) so the API
 *      boots with zero setup and no secrets. Data is ephemeral.
 *
 * `maxPoolSize` is kept small to respect Atlas free-tier (M0) connection limits.
 */
async function connect() {
  if (mongoose.connection.readyState === 1) return mongoose.connection;

  let uri = env.mongoUri;

  if (!uri) {
    // Lazy require: mongodb-memory-server is a devDependency and may be absent
    // in a production install.
    let MongoMemoryServer;
    try {
      ({ MongoMemoryServer } = require('mongodb-memory-server'));
    } catch (err) {
      throw new Error(
        'MONGODB_URI is not set and mongodb-memory-server is not installed. ' +
          'Set MONGODB_URI (local or Atlas) or install dev dependencies.'
      );
    }
    memoryServer = await MongoMemoryServer.create();
    uri = memoryServer.getUri('aarvy_hospital');
    if (!env.isTest) {
      console.log('[db] No MONGODB_URI set — using in-memory MongoDB (ephemeral).');
    }
  }

  await mongoose.connect(uri, {
    maxPoolSize: 10,
    serverSelectionTimeoutMS: 10000,
  });

  return mongoose.connection;
}

async function disconnect() {
  await mongoose.disconnect();
  if (memoryServer) {
    await memoryServer.stop();
    memoryServer = null;
  }
}

module.exports = { connect, disconnect, mongoose };
