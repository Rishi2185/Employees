'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const { makeDoctor, daysFromNow } = require('./helpers');

const app = createApp();

/**
 * Guards the wire contract with the patient Flutter app. Its Appointment.fromJson
 * reads these exact keys and reconstructs enums via `Enum.values[index]`, so the
 * API must emit integer `status`/`paymentMethod` (0..2) and an ISO `dateTime`.
 * A drift here (e.g. string enums, a 4th status) would crash the patient app.
 */
describe('patient-app Appointment contract', () => {
  beforeEach(async () => {
    await makeDoctor({ _id: 'd1', consultationFee: 500, photoUrl: 'http://x/p.jpg' });
  });

  test('appointment JSON satisfies Appointment.fromJson expectations', async () => {
    const res = await request(app)
      .post('/api/appointments')
      .send({
        doctorId: 'd1',
        dateTime: daysFromNow(1).toISOString(),
        slotLabel: '10:00 AM',
        paymentMethod: 1,
      });
    expect(res.status).toBe(201);
    const a = res.body;

    // Required keys + types the patient model's fromJson casts.
    expect(typeof a.id).toBe('string');
    expect(typeof a.doctorId).toBe('string');
    expect(typeof a.doctorName).toBe('string');
    expect(typeof a.doctorPhotoUrl).toBe('string');
    expect(typeof a.specialtyName).toBe('string');
    expect(typeof a.hospitalName).toBe('string');
    expect(typeof a.slotLabel).toBe('string');
    expect(Number.isInteger(a.fee)).toBe(true);
    expect(typeof a.reviewed).toBe('boolean');

    // Enum indices must be integers within the patient enum's range.
    expect(Number.isInteger(a.status)).toBe(true);
    expect(a.status).toBeGreaterThanOrEqual(0);
    expect(a.status).toBeLessThanOrEqual(2);
    expect(Number.isInteger(a.paymentMethod)).toBe(true);
    expect(a.paymentMethod).toBeGreaterThanOrEqual(0);
    expect(a.paymentMethod).toBeLessThanOrEqual(2);

    // dateTime must be an ISO-8601 string DateTime.parse can read.
    expect(typeof a.dateTime).toBe('string');
    expect(Number.isNaN(Date.parse(a.dateTime))).toBe(false);

    // Simulate the Dart fromJson round-trip — must not throw / lose data.
    const rebuilt = {
      id: a.id,
      doctorId: a.doctorId,
      dateTime: new Date(a.dateTime),
      status: a.status,
      paymentMethod: a.paymentMethod,
      reviewed: a.reviewed ?? false,
    };
    expect(rebuilt.dateTime.toISOString()).toBe(new Date(a.dateTime).toISOString());
  });
});
