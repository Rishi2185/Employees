'use strict';

const User = require('../src/models/User');
const Doctor = require('../src/models/Doctor');
const env = require('../src/config/env');
const { signToken } = require('../src/middleware/auth');
const { dayKey } = require('../src/utils/dayKey');

let counter = 0;

/** Create a user of the given role and return a signed JWT for it. */
async function tokenFor(role) {
  counter += 1;
  const user = await User.create({
    username: `${role}_${counter}`,
    passwordHash: await User.hashPassword('pw', env.bcryptRounds),
    role,
    displayName: `${role} ${counter}`,
  });
  return { token: signToken(user), user };
}

const bearer = (token) => `Bearer ${token}`;

/** Seed a doctor (defaults are valid for booking). */
async function makeDoctor(overrides = {}) {
  return Doctor.create({
    _id: overrides._id || 'd1',
    name: 'Dr. Test',
    specialtyId: 'cardiology',
    specialtyName: 'Cardiology',
    qualifications: 'MBBS',
    experienceYears: 5,
    rating: 4.5,
    consultationFee: 500,
    hospitalId: 'h1',
    hospitalName: 'Test Hospital',
    availableToday: true,
    availableDays: ['Mon', 'Tue'],
    active: true,
    ...overrides,
  });
}

/** A Date a given number of days from now (UTC noon — safe day bucketing). */
function daysFromNow(n) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() + n);
  d.setUTCHours(6, 0, 0, 0); // ~11:30 IST
  return d;
}

module.exports = { tokenFor, bearer, makeDoctor, daysFromNow, dayKey };
