'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const Appointment = require('../src/models/Appointment');
const DailySummary = require('../src/models/DailySummary');
const { tokenFor, bearer, makeDoctor, daysFromNow, dayKey } = require('./helpers');
const { todayKey } = require('../src/utils/dayKey');
const { APPOINTMENT_STATUS, APPOINTMENT_SOURCE } = require('../src/constants');

const app = createApp();

// Insert full records directly for a past day (the create endpoint forbids
// past-dated bookings; we're simulating a day that has since completed).
async function seedPastDay(key, when) {
  await Appointment.insertMany([
    { doctorId: 'd1', doctorName: 'Dr. One', dateTime: when, slotLabel: '09:30 AM', fee: 500, status: APPOINTMENT_STATUS.COMPLETED, dayKey: key, patientName: 'A', patientPhone: '1' },
    { doctorId: 'd1', doctorName: 'Dr. One', dateTime: when, slotLabel: '10:00 AM', fee: 700, status: APPOINTMENT_STATUS.COMPLETED, dayKey: key, source: APPOINTMENT_SOURCE.RECEPTION_WALKIN, patientName: 'B', patientPhone: '2' },
    { doctorId: 'd1', doctorName: 'Dr. One', dateTime: when, slotLabel: '11:00 AM', fee: 500, status: APPOINTMENT_STATUS.CANCELLED, dayKey: key, patientName: 'C', patientPhone: '3' },
  ]);
}

describe('end-of-day: summarize -> purge', () => {
  let reception;
  beforeEach(async () => {
    await makeDoctor({ _id: 'd1', name: 'Dr. One' });
    ({ token: reception } = await tokenFor('reception'));
  });

  test('summary is server-computed and idempotent (upsert by dayKey)', async () => {
    const when = daysFromNow(-1);
    const key = dayKey(when);
    await seedPastDay(key, when);

    const first = await request(app)
      .post('/api/summaries')
      .set('Authorization', bearer(reception))
      .send({ dayKey: key });
    expect(first.status).toBe(201);
    expect(first.body.dayKey).toBe(key);
    expect(first.body.overall).toMatchObject({ total: 3, completed: 2, cancelled: 1, walkIns: 1 });
    expect(first.body.overall.revenue).toBe(1200); // 500 + 700 completed

    // Re-running overwrites the same doc — no duplicate.
    const again = await request(app)
      .post('/api/summaries')
      .set('Authorization', bearer(reception))
      .send({ dayKey: key });
    expect(again.status).toBe(201);
    expect(await DailySummary.countDocuments({ _id: key })).toBe(1);
  });

  test('cannot summarize today (still mutating) -> 400', async () => {
    const res = await request(app)
      .post('/api/summaries')
      .set('Authorization', bearer(reception))
      .send({ dayKey: todayKey() });
    expect(res.status).toBe(400);
  });

  test('purge is refused until a summary exists (precondition)', async () => {
    const when = daysFromNow(-1);
    const key = dayKey(when);
    await seedPastDay(key, when);

    const blocked = await request(app)
      .delete(`/api/appointments?date=${key}&confirm=${key}`)
      .set('Authorization', bearer(reception));
    expect(blocked.status).toBe(409); // no summary yet
    expect(await Appointment.countDocuments({ dayKey: key })).toBe(3); // untouched
  });

  test('full lifecycle: summarize, then purge, then idempotent re-purge', async () => {
    const when = daysFromNow(-2);
    const key = dayKey(when);
    await seedPastDay(key, when);

    await request(app)
      .post('/api/summaries')
      .set('Authorization', bearer(reception))
      .send({ dayKey: key })
      .expect(201);

    const purged = await request(app)
      .delete(`/api/appointments?date=${key}&confirm=${key}`)
      .set('Authorization', bearer(reception));
    expect(purged.status).toBe(200);
    expect(purged.body.deleted).toBe(3);
    expect(await Appointment.countDocuments({ dayKey: key })).toBe(0);

    // Summary survives the purge (history preserved).
    expect(await DailySummary.countDocuments({ _id: key })).toBe(1);

    // Re-purging an already-empty day is a no-op, not an error.
    const rePurge = await request(app)
      .delete(`/api/appointments?date=${key}&confirm=${key}`)
      .set('Authorization', bearer(reception));
    expect(rePurge.status).toBe(200);
    expect(rePurge.body.deleted).toBe(0);
  });

  test('purge rejects confirm mismatch and today', async () => {
    const when = daysFromNow(-1);
    const key = dayKey(when);
    await seedPastDay(key, when);
    await request(app).post('/api/summaries').set('Authorization', bearer(reception)).send({ dayKey: key });

    const mismatch = await request(app)
      .delete(`/api/appointments?date=${key}&confirm=2000-01-01`)
      .set('Authorization', bearer(reception));
    expect(mismatch.status).toBe(400);

    const today = todayKey();
    const purgeToday = await request(app)
      .delete(`/api/appointments?date=${today}&confirm=${today}`)
      .set('Authorization', bearer(reception));
    expect(purgeToday.status).toBe(400);
  });

  test('admin can read historical summaries via range + per-doctor slice', async () => {
    const when = daysFromNow(-1);
    const key = dayKey(when);
    await seedPastDay(key, when);
    await request(app).post('/api/summaries').set('Authorization', bearer(reception)).send({ dayKey: key });

    const { token: admin } = await tokenFor('admin');
    const range = await request(app)
      .get(`/api/summaries?from=2000-01-01&to=2999-12-31&doctorId=d1`)
      .set('Authorization', bearer(admin));
    expect(range.status).toBe(200);
    const row = range.body.data.find((r) => r.dayKey === key);
    expect(row).toMatchObject({ doctorId: 'd1', total: 3, completed: 2, cancelled: 1 });
  });
});
