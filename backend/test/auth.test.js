'use strict';

const request = require('supertest');
const createApp = require('../src/app');
const User = require('../src/models/User');
const env = require('../src/config/env');
const { tokenFor, bearer } = require('./helpers');

const app = createApp();

describe('auth & role gating', () => {
  test('login returns a token for valid credentials', async () => {
    await User.create({
      username: 'admin',
      passwordHash: await User.hashPassword('secret', env.bcryptRounds),
      role: 'admin',
      displayName: 'Admin',
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'secret' });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeTruthy();
    expect(res.body.role).toBe('admin');
  });

  test('login rejects a wrong password with 401', async () => {
    await User.create({
      username: 'admin',
      passwordHash: await User.hashPassword('secret', env.bcryptRounds),
      role: 'admin',
      displayName: 'Admin',
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: 'admin', password: 'nope' });

    expect(res.status).toBe(401);
  });

  test('GET /me echoes the authenticated principal', async () => {
    const { token } = await tokenFor('reception');
    const res = await request(app).get('/api/auth/me').set('Authorization', bearer(token));
    expect(res.status).toBe(200);
    expect(res.body.role).toBe('reception');
  });

  test('reception cannot create a doctor (admin-only) -> 403', async () => {
    const { token } = await tokenFor('reception');
    const res = await request(app)
      .post('/api/doctors')
      .set('Authorization', bearer(token))
      .send({ name: 'X', specialtyId: 'general', specialtyName: 'General' });
    expect(res.status).toBe(403);
  });

  test('missing token on a protected route -> 401', async () => {
    const res = await request(app).get('/api/appointments');
    expect(res.status).toBe(401);
  });
});
