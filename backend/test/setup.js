'use strict';

const mongoose = require('mongoose');
const { connect, disconnect } = require('../src/config/db');

// Register every model so indexes (unique slot, TTL, ...) are built.
require('../src/models/User');
require('../src/models/Specialty');
require('../src/models/Hospital');
require('../src/models/Doctor');
require('../src/models/Appointment');
require('../src/models/DailySummary');

beforeAll(async () => {
  await connect();
  // Build indexes before any test relies on the unique slot constraint.
  await Promise.all(Object.values(mongoose.models).map((m) => m.init()));
});

afterEach(async () => {
  const { collections } = mongoose.connection;
  await Promise.all(Object.values(collections).map((c) => c.deleteMany({})));
});

afterAll(async () => {
  await disconnect();
});
