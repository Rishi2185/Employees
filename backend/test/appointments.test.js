'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const { tokenFor, bearer, makeDoctor, daysFromNow } = require('./helpers');

const app = createApp();

describe('appointments — booking', () => {
  beforeEach(async () => {
    await makeDoctor({ _id: 'd1', consultationFee: 500 });
  });

  test('anonymous patient booking succeeds (identity optional)', async () => {
    const res = await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'd1', dateTime: daysFromNow(1).toISOString(), slotLabel: '10:00 AM' });

    expect(res.status).toBe(201);
    expect(res.body.source).toBe('patient_app');
    expect(res.body.status).toBe(0); // upcoming
    expect(res.body.doctorName).toBe('Dr. Test'); // denormalized from doctor
    expect(res.body.fee).toBe(500); // derived from doctor fee
  });

  test('reception walk-in requires patient name + phone', async () => {
    const { token } = await tokenFor('reception');
    const bad = await request(app)
      .post('/api/appointments')
      .set('Authorization', bearer(token))
      .send({ doctorId: 'd1', dateTime: daysFromNow(1).toISOString(), slotLabel: '10:30 AM' });
    expect(bad.status).toBe(400);

    const ok = await request(app)
      .post('/api/appointments')
      .set('Authorization', bearer(token))
      .send({
        doctorId: 'd1',
        dateTime: daysFromNow(1).toISOString(),
        slotLabel: '10:30 AM',
        patientName: 'Walk In',
        patientPhone: '9990001112',
      });
    expect(ok.status).toBe(201);
    expect(ok.body.source).toBe('reception_walkin');
  });

  test('double-booking the same doctor/day/slot is rejected (409)', async () => {
    const slot = { doctorId: 'd1', dateTime: daysFromNow(2).toISOString(), slotLabel: '11:00 AM' };
    const first = await request(app).post('/api/appointments').send(slot);
    expect(first.status).toBe(201);

    const second = await request(app).post('/api/appointments').send(slot);
    expect(second.status).toBe(409);
  });

  test('booking into a past day is rejected (400)', async () => {
    const res = await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'd1', dateTime: daysFromNow(-1).toISOString(), slotLabel: '09:00 AM' });
    expect(res.status).toBe(400);
  });

  test('unknown doctor is rejected (400)', async () => {
    const res = await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'nope', dateTime: daysFromNow(1).toISOString(), slotLabel: '09:00 AM' });
    expect(res.status).toBe(400);
  });
});

describe('appointments — manage & list', () => {
  beforeEach(async () => {
    await makeDoctor({ _id: 'd1' });
  });

  test('reception can mark an appointment completed', async () => {
    const created = await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'd1', dateTime: daysFromNow(1).toISOString(), slotLabel: '10:00 AM' });
    const { token } = await tokenFor('reception');

    const patched = await request(app)
      .patch(`/api/appointments/${created.body.id}`)
      .set('Authorization', bearer(token))
      .send({ status: 1, checkedIn: true });

    expect(patched.status).toBe(200);
    expect(patched.body.status).toBe(1);
    expect(patched.body.statusLabel).toBe('completed');
  });

  test('list filters by doctorId and returns a paginated envelope', async () => {
    await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'd1', dateTime: daysFromNow(1).toISOString(), slotLabel: '10:00 AM' });
    const { token } = await tokenFor('reception');

    const res = await request(app)
      .get('/api/appointments?doctorId=d1')
      .set('Authorization', bearer(token));

    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('page');
    expect(res.body).toHaveProperty('limit');
    expect(res.body).toHaveProperty('total', 1);
    expect(res.body.data[0].doctorId).toBe('d1');
  });

  test('slip endpoint returns a printable payload', async () => {
    const created = await request(app)
      .post('/api/appointments')
      .send({ doctorId: 'd1', dateTime: daysFromNow(1).toISOString(), slotLabel: '10:00 AM' });
    const { token } = await tokenFor('reception');

    const res = await request(app)
      .get(`/api/appointments/${created.body.id}/slip`)
      .set('Authorization', bearer(token));

    expect(res.status).toBe(200);
    expect(res.body.appointmentId).toBe(created.body.id);
    expect(res.body.doctorName).toBe('Dr. Test');
  });
});
