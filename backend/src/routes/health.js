'use strict';

const express = require('express');
const mongoose = require('mongoose');

const router = express.Router();

// GET /api/health — DB connectivity probe for the desktop/admin apps.
router.get('/', (_req, res) => {
  const states = ['disconnected', 'connected', 'connecting', 'disconnecting'];
  const state = states[mongoose.connection.readyState] || 'unknown';
  res.json({
    status: 'ok',
    db: state,
    time: new Date().toISOString(),
  });
});

module.exports = router;
