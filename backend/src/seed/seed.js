'use strict';

const env = require('../config/env');
const { connect, disconnect } = require('../config/db');
const { todayKey } = require('../utils/dayKey');

const User = require('../models/User');
const Specialty = require('../models/Specialty');
const Hospital = require('../models/Hospital');
const Doctor = require('../models/Doctor');
const Appointment = require('../models/Appointment');
const DailySummary = require('../models/DailySummary');

const { specialties, hospitals } = require('./data');

/**
 * Seed the database. Assumes a live Mongoose connection (caller owns it).
 * Clears the relevant collections first so it is safe to re-run.
 *
 * Note: doctors are NOT seeded — the roster is managed from the admin app via
 * the doctor CRUD endpoints and written to the shared `doctors` collection.
 * Appointments and daily summaries reference doctors, so they are not seeded
 * either; they accrue at runtime once real doctors exist.
 */
async function seedDatabase({ log = () => {} } = {}) {
  log('clearing collections...');
  await Promise.all([
    User.deleteMany({}),
    Specialty.deleteMany({}),
    Hospital.deleteMany({}),
    Doctor.deleteMany({}),
    Appointment.deleteMany({}),
    DailySummary.deleteMany({}),
  ]);

  log('inserting specialties, hospitals...');
  await Specialty.insertMany(specialties);
  await Hospital.insertMany(hospitals);

  log('creating users (admin + reception)...');
  await User.create([
    {
      username: env.seed.adminUser,
      passwordHash: await User.hashPassword(env.seed.adminPass, env.bcryptRounds),
      role: 'admin',
      displayName: 'Hospital Admin',
    },
    {
      username: env.seed.receptionUser,
      passwordHash: await User.hashPassword(env.seed.receptionPass, env.bcryptRounds),
      role: 'reception',
      displayName: 'Front Desk',
    },
  ]);

  return {
    specialties: specialties.length,
    hospitals: hospitals.length,
    doctors: 0,
    appointments: 0,
    summaries: 0,
    today: todayKey(),
  };
}

// CLI entrypoint: `npm run seed`. Owns its own connection.
async function runCli() {
  await connect();
  const result = await seedDatabase({ log: (m) => console.log(`[seed] ${m}`) });
  console.log('\n[seed] done.');
  console.log(`  specialties: ${result.specialties}`);
  console.log(`  hospitals:   ${result.hospitals}`);
  console.log(`  doctors:     ${result.doctors}  (add doctors from the admin app)`);
  console.log(`  appointments:${result.appointments}  (today=${result.today})`);
  console.log(`  summaries:   ${result.summaries}`);
  console.log('\n  Login:');
  console.log(`    admin     -> ${env.seed.adminUser} / ${env.seed.adminPass}`);
  console.log(`    reception -> ${env.seed.receptionUser} / ${env.seed.receptionPass}`);
  if (!env.mongoUri) {
    console.log(
      '\n  NOTE: No MONGODB_URI set, so this seeded an EPHEMERAL in-memory DB ' +
        'that is gone now. Set MONGODB_URI (local mongod or Atlas) to persist, ' +
        'or just run `npm run dev` — it auto-seeds an empty in-memory DB on boot.'
    );
  }
  await disconnect();
}

if (require.main === module) {
  runCli()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[seed] failed:', err);
      process.exit(1);
    });
}

module.exports = { seedDatabase };
