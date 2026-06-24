'use strict';

const env = require('../config/env');
const { connect, disconnect } = require('../config/db');
const { dayKey, todayKey } = require('../utils/dayKey');

const User = require('../models/User');
const Specialty = require('../models/Specialty');
const Hospital = require('../models/Hospital');
const Doctor = require('../models/Doctor');
const Appointment = require('../models/Appointment');
const DailySummary = require('../models/DailySummary');

const { specialties, hospitals, doctors } = require('./data');
const { APPOINTMENT_STATUS, PAYMENT_METHOD, APPOINTMENT_SOURCE } = require('../constants');

// Build a Date for a given day offset at a UTC hour chosen to land in daytime
// for the default clinic TZ (Asia/Kolkata, UTC+5:30). dayKey is derived from the
// resulting instant so the stored day is always internally consistent.
function at(dayOffset, utcHour, utcMin = 0) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + dayOffset);
  d.setUTCHours(utcHour, utcMin, 0, 0);
  return d;
}

function appt(partial) {
  return {
    fee: 500,
    paymentMethod: PAYMENT_METHOD.UPI,
    status: APPOINTMENT_STATUS.UPCOMING,
    reviewed: false,
    source: APPOINTMENT_SOURCE.PATIENT_APP,
    checkedIn: false,
    dayKey: dayKey(partial.dateTime),
    ...partial,
  };
}

/**
 * Seed the database. Assumes a live Mongoose connection (caller owns it).
 * Clears the relevant collections first so it is safe to re-run.
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

  log('inserting specialties, hospitals, doctors...');
  await Specialty.insertMany(specialties);
  await Hospital.insertMany(hospitals);
  await Doctor.insertMany(doctors);

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

  log('inserting sample appointments (today + future)...');
  const byId = Object.fromEntries(doctors.map((d) => [d._id, d]));
  const D = (id) => byId[id];
  const sample = [
    appt({
      doctorId: 'd1', doctorName: D('d1').name, doctorPhotoUrl: D('d1').photoUrl,
      specialtyName: D('d1').specialtyName, hospitalName: D('d1').hospitalName,
      dateTime: at(0, 4, 0), slotLabel: '09:30 AM', fee: 849,
      patientName: 'Asha Menon', patientPhone: '9810011001',
      status: APPOINTMENT_STATUS.COMPLETED, checkedIn: true,
    }),
    appt({
      doctorId: 'd1', doctorName: D('d1').name, doctorPhotoUrl: D('d1').photoUrl,
      specialtyName: D('d1').specialtyName, hospitalName: D('d1').hospitalName,
      dateTime: at(0, 5, 30), slotLabel: '11:00 AM', fee: 849,
      patientName: 'Rakesh Gupta', patientPhone: '9810022002',
      source: APPOINTMENT_SOURCE.RECEPTION_WALKIN, tokenNumber: 12,
    }),
    appt({
      doctorId: 'd8', doctorName: D('d8').name, doctorPhotoUrl: D('d8').photoUrl,
      specialtyName: D('d8').specialtyName, hospitalName: D('d8').hospitalName,
      dateTime: at(0, 7, 0), slotLabel: '12:30 PM', fee: 449,
      patientName: 'Fatima Sheikh', patientPhone: '9810033003',
    }),
    appt({
      doctorId: 'd11', doctorName: D('d11').name, doctorPhotoUrl: D('d11').photoUrl,
      specialtyName: D('d11').specialtyName, hospitalName: D('d11').hospitalName,
      dateTime: at(0, 9, 0), slotLabel: '02:30 PM', fee: 1049,
      patientName: 'John Mathew', patientPhone: '9810044004',
      status: APPOINTMENT_STATUS.CANCELLED,
    }),
    appt({
      doctorId: 'd1', doctorName: D('d1').name, doctorPhotoUrl: D('d1').photoUrl,
      specialtyName: D('d1').specialtyName, hospitalName: D('d1').hospitalName,
      dateTime: at(4, 4, 0), slotLabel: '09:30 AM', fee: 849,
      patientName: 'Neha Verma', patientPhone: '9810055005',
    }),
    appt({
      doctorId: 'd3', doctorName: D('d3').name, doctorPhotoUrl: D('d3').photoUrl,
      specialtyName: D('d3').specialtyName, hospitalName: D('d3').hospitalName,
      dateTime: at(4, 5, 30), slotLabel: '11:00 AM', fee: 799,
      patientName: 'Priyanka Roy', patientPhone: '9810066006',
    }),
  ];
  await Appointment.insertMany(sample);

  log('inserting historical daily summaries (past 3 days)...');
  const past = [1, 2, 3].map((n) => dayKey(at(-n, 6, 0)));
  const histDocs = past.map((key, i) => ({
    _id: key,
    date: new Date(`${key}T00:00:00.000Z`),
    overall: {
      total: 18 + i * 3,
      completed: 14 + i * 2,
      cancelled: 2,
      pending: 0,
      walkIns: 4 + i,
      revenue: (14 + i * 2) * 600,
    },
    perDoctor: [
      { doctorId: 'd1', doctorName: D('d1').name, total: 6, completed: 5, cancelled: 1, pending: 0 },
      { doctorId: 'd8', doctorName: D('d8').name, total: 7 + i, completed: 6 + i, cancelled: 0, pending: 0 },
      { doctorId: 'd11', doctorName: D('d11').name, total: 5 + i, completed: 3 + i, cancelled: 1, pending: 0 },
    ],
    generatedBy: 'seed',
    version: 1,
  }));
  await DailySummary.insertMany(histDocs);

  return {
    specialties: specialties.length,
    hospitals: hospitals.length,
    doctors: doctors.length,
    appointments: sample.length,
    summaries: histDocs.length,
    today: todayKey(),
    pastDays: past,
  };
}

// CLI entrypoint: `npm run seed`. Owns its own connection.
async function runCli() {
  await connect();
  const result = await seedDatabase({ log: (m) => console.log(`[seed] ${m}`) });
  console.log('\n[seed] done.');
  console.log(`  specialties: ${result.specialties}`);
  console.log(`  hospitals:   ${result.hospitals}`);
  console.log(`  doctors:     ${result.doctors}`);
  console.log(`  appointments:${result.appointments}  (today=${result.today})`);
  console.log(`  summaries:   ${result.summaries}  (${result.pastDays.join(', ')})`);
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
