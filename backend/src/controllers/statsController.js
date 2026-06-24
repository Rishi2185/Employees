'use strict';

const statsService = require('../services/statsService');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { normalizeDayKey } = require('../utils/dayKey');

// GET /api/stats/today
const today = asyncHandler(async (_req, res) => {
  res.json(await statsService.today());
});

// GET /api/stats/doctors?date=YYYY-MM-DD
const doctors = asyncHandler(async (req, res) => {
  let key = null;
  if (req.query.date) {
    key = normalizeDayKey(req.query.date);
    if (!key) throw ApiError.badRequest('date must be YYYY-MM-DD');
  }
  res.json(await statsService.doctorsForDay(key));
});

// GET /api/stats/live (admin)
const live = asyncHandler(async (_req, res) => {
  res.json(await statsService.live());
});

// GET /api/stats/overview
const overview = asyncHandler(async (_req, res) => {
  res.json(await statsService.overview());
});

module.exports = { today, doctors, live, overview };
