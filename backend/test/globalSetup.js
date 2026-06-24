'use strict';

const { MongoMemoryServer } = require('mongodb-memory-server');

// One shared in-memory MongoDB for the whole suite. The URI is exported via
// process.env so each (run-in-band) test worker inherits it; env.js then reads
// it at load time. Lowering bcrypt rounds keeps auth-heavy tests fast.
module.exports = async function globalSetup() {
  const instance = await MongoMemoryServer.create();
  globalThis.__MONGO_INSTANCE__ = instance;
  process.env.MONGODB_URI = instance.getUri('aarvy_test');
  process.env.BCRYPT_ROUNDS = '4';
  process.env.JWT_SECRET = 'test-secret';
  process.env.CLINIC_TZ = process.env.CLINIC_TZ || 'Asia/Kolkata';
};
