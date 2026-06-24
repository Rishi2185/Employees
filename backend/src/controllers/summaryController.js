'use strict';

const summaryService = require('../services/summaryService');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');

// POST /api/summaries (reception) — end-of-day write (server-computed, idempotent)
const write = asyncHandler(async (req, res) => {
  const summary = await summaryService.write(
    req.body.dayKey,
    req.user ? req.user.id : undefined
  );
  res.status(201).json(summary);
});

// GET /api/summaries?from&to&doctorId (admin) — historical trends
const range = asyncHandler(async (req, res) => {
  res.json(await summaryService.range(req.validatedQuery));
});

// GET /api/summaries/:dayKey
const getByDay = asyncHandler(async (req, res) => {
  const summary = await summaryService.getByDay(req.params.dayKey);
  if (!summary) throw ApiError.notFound('No summary for that day');
  res.json(summary);
});

module.exports = { write, range, getByDay };
