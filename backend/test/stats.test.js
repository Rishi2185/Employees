'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const Appointment = require('../src/models/Appointment');
const DailySummary = require('../src/models/DailySummary');
const { tokenFor, bearer, makeDoctor } = require('./helpers');
const { todayKey } = require('../src/utils/dayKey');
const { APPOINTMENT_STATUS, APPOINTMENT_SOURCE } = require('../src/constants');

const app = createApp();

function todayAt(hourUtc) {
  const d = new Date();
  d.setUTCHours(hourUtc, 0, 0, 0);
  return d;
}

describe('stats', () => {
  let token;
  beforeEach(async () => {
    await makeDoctor({ _id: 'd1', name: 'Dr. One' });
    const key = todayKey();
    await Appointment.insertMany([
      { doctorId: 'd1', doctorName: 'Dr. One', dateTime: todayAt(4), slotLabel: '09:30 AM', fee: 500, status: APPOINTMENT_STATUS.COMPLETED, dayKey: key },
      { doctorId: 'd1', doctorName: 'Dr. One', dateTime: todayAt(5), slotLabel: '11:00 AM', fee: 500, status: APPOINTMENT_STATUS.UPCOMING, dayKey: key, source: APPOINTMENT_SOURCE.RECEPTION_WALKIN },
      { doctorId: 'd1', doctorName: 'Dr. One', dateTime: todayAt(6), slotLabel: '12:30 PM', fee: 500, status: APPOINTMENT_STATUS.CANCELLED, dayKey: key },
    ]);
    ({ token } = await tokenFor('reception'));
  });

  test('GET /stats/today returns today counts', async () => {
    const res = await request(app).get('/api/stats/today').set('Authorization', bearer(token));
    expect(res.status).toBe(200);
    expect(res.body.todaysAppointments).toBe(3);
    expect(res.body.completed).toBe(1);
    expect(res.body.pending).toBe(1);
    expect(res.body.cancelled).toBe(1);
    expect(res.body.walkIns).toBe(1);
  });

  test('GET /stats/doctors returns per-doctor breakdown', async () => {
    const res = await request(app).get('/api/stats/doctors').set('Authorization', bearer(token));
    expect(res.status).toBe(200);
    expect(res.body.perDoctor).toHaveLength(1);
    expect(res.body.perDoctor[0]).toMatchObject({
      doctorId: 'd1',
      total: 3,
      completed: 1,
      pending: 1,
      cancelled: 1,
    });
  });

  test('GET /stats/overview derives all-time visits from summaries + today', async () => {
    await DailySummary.create({
      _id: '2026-01-01',
      date: new Date('2026-01-01T00:00:00.000Z'),
      overall: { total: 40, completed: 35, cancelled: 5, pending: 0, walkIns: 10, revenue: 21000 },
      perDoctor: [],
    });

    const res = await request(app).get('/api/stats/overview').set('Authorization', bearer(token));
    expect(res.status).toBe(200);
    expect(res.body.historicalVisits).toBe(40);
    expect(res.body.todaysAppointments).toBe(3);
    expect(res.body.totalPatientsAllTime).toBe(43); // 40 historical + 3 today
  });

  test('GET /stats/live is admin-only', async () => {
    const reception = await request(app).get('/api/stats/live').set('Authorization', bearer(token));
    expect(reception.status).toBe(403);

    const { token: adminToken } = await tokenFor('admin');
    const admin = await request(app).get('/api/stats/live').set('Authorization', bearer(adminToken));
    expect(admin.status).toBe(200);
    expect(admin.body.today.todaysAppointments).toBe(3);
  });
});
