'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const Doctor = require('../src/models/Doctor');
const { tokenFor, bearer } = require('./helpers');

const app = createApp();

async function seedRoster() {
  await Doctor.insertMany([
    { _id: 'd1', name: 'Dr. Ananya Sharma', specialtyId: 'cardiology', specialtyName: 'Cardiology', qualifications: 'MBBS, DM', rating: 4.9, consultationFee: 800, experienceYears: 14, availableToday: true, active: true },
    { _id: 'd2', name: 'Dr. Rohan Mehta', specialtyId: 'dermatology', specialtyName: 'Dermatology', qualifications: 'MBBS, MD', rating: 4.7, consultationFee: 600, experienceYears: 9, availableToday: true, active: true },
    { _id: 'd11', name: 'Dr. Ishaan Joshi', specialtyId: 'cardiology', specialtyName: 'Cardiology', qualifications: 'MBBS, DNB', rating: 4.5, consultationFee: 1000, experienceYears: 20, availableToday: false, active: true },
    { _id: 'd9', name: 'Dr. Retired', specialtyId: 'dentistry', specialtyName: 'Dentistry', rating: 4.0, consultationFee: 450, experienceYears: 7, availableToday: true, active: false },
  ]);
}

describe('doctors list — parity with patient DoctorProvider', () => {
  beforeEach(seedRoster);

  test('excludes inactive doctors by default', async () => {
    const res = await request(app).get('/api/doctors');
    expect(res.status).toBe(200);
    const ids = res.body.data.map((d) => d.id);
    expect(ids).not.toContain('d9');
    expect(res.body.total).toBe(3);
  });

  test('filters by specialtyId', async () => {
    const res = await request(app).get('/api/doctors?specialtyId=cardiology');
    expect(res.body.data.map((d) => d.id).sort()).toEqual(['d1', 'd11']);
  });

  test('availableToday=true filters', async () => {
    const res = await request(app).get('/api/doctors?availableToday=true');
    const ids = res.body.data.map((d) => d.id);
    expect(ids).toContain('d1');
    expect(ids).not.toContain('d11');
  });

  test('minRating filters', async () => {
    const res = await request(app).get('/api/doctors?minRating=4.8');
    expect(res.body.data.map((d) => d.id)).toEqual(['d1']);
  });

  test('q matches name/specialty/qualifications (case-insensitive)', async () => {
    const res = await request(app).get('/api/doctors?q=ishaan');
    expect(res.body.data.map((d) => d.id)).toEqual(['d11']);
  });

  test('sort=feeLow orders by consultationFee ascending', async () => {
    const res = await request(app).get('/api/doctors?sort=feeLow');
    const fees = res.body.data.map((d) => d.consultationFee);
    expect(fees).toEqual([...fees].sort((a, b) => a - b));
  });

  test('relevance == rating desc', async () => {
    const res = await request(app).get('/api/doctors?sort=relevance');
    const ratings = res.body.data.map((d) => d.rating);
    expect(ratings).toEqual([...ratings].sort((a, b) => b - a));
  });
});

describe('doctors admin CRUD', () => {
  test('admin can create, update and soft-delete', async () => {
    const { token } = await tokenFor('admin');

    const created = await request(app)
      .post('/api/doctors')
      .set('Authorization', bearer(token))
      .send({ name: 'Dr. New', specialtyId: 'ent', specialtyName: 'ENT', consultationFee: 700 });
    expect(created.status).toBe(201);
    const id = created.body.id;

    const updated = await request(app)
      .patch(`/api/doctors/${id}`)
      .set('Authorization', bearer(token))
      .send({ consultationFee: 750 });
    expect(updated.status).toBe(200);
    expect(updated.body.consultationFee).toBe(750);

    const removed = await request(app)
      .delete(`/api/doctors/${id}`)
      .set('Authorization', bearer(token));
    expect(removed.status).toBe(200);
    expect(removed.body.active).toBe(false);

    // Soft-deleted doctor disappears from the default public list.
    const list = await request(app).get('/api/doctors');
    expect(list.body.data.map((d) => d.id)).not.toContain(id);
  });

  test('unknown field is rejected (strict schema)', async () => {
    const { token } = await tokenFor('admin');
    const res = await request(app)
      .post('/api/doctors')
      .set('Authorization', bearer(token))
      .send({ name: 'X', specialtyId: 'ent', specialtyName: 'ENT', role: 'admin' });
    expect(res.status).toBe(400);
  });
});
