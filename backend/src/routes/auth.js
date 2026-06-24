'use strict';

const express = require('express');
const validate = require('../middleware/validate');
const { requireAuth } = require('../middleware/auth');
const { authLimiter } = require('../middleware/rateLimiters');
const { loginSchema } = require('../validators/authValidators');
const { login, me } = require('../controllers/authController');

const router = express.Router();

router.post('/login', authLimiter, validate(loginSchema), login);
router.get('/me', requireAuth, me);

module.exports = router;
