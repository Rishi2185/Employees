'use strict';

const DailySummary = require('../models/DailySummary');
const statsService = require('./statsService');
const ApiError = require('../utils/apiError');
const { todayKey, normalizeDayKey } = require('../utils/dayKey');

/**
 * Write (idempotent upsert) the daily summary for a completed day. The counts
 * are computed SERVER-SIDE from the live appointments store — reception only
 * names the day — so client clock skew or bugs can never corrupt history.
 *
 * Guard: only days strictly in the past may be summarized (a still-mutating
 * day would produce a wrong total).
 */
async function write(rawDayKey, generatedBy) {
  const key = normalizeDayKey(rawDayKey);
  if (!key) throw ApiError.badRequest('dayKey must be a valid YYYY-MM-DD');
  if (!(key < todayKey())) {
    throw ApiError.badRequest('Can only summarize days strictly in the past');
  }

  const { overall, perDoctor } = await statsService.computeDay(key);

  const doc = await DailySummary.findByIdAndUpdate(
    key,
    {
      _id: key,
      date: new Date(`${key}T00:00:00.000Z`),
      overall,
      perDoctor,
      generatedAt: new Date(),
      generatedBy: generatedBy || undefined,
      version: 1,
    },
    { new: true, upsert: true, setDefaultsOnInsert: true }
  );

  return doc.toJSON();
}

/** GET /summaries?from&to&doctorId — historical trends for the admin app. */
async function range({ from, to, doctorId }) {
  const filter = {};
  if (from || to) {
    filter._id = {};
    if (from) filter._id.$gte = from;
    if (to) filter._id.$lte = to;
  }

  const docs = await DailySummary.find(filter).sort({ _id: 1 });
  let data = docs.map((d) => d.toJSON());

  // Slice to a single doctor's per-day numbers when requested.
  if (doctorId) {
    data = data.map((s) => {
      const d = (s.perDoctor || []).find((p) => p.doctorId === doctorId);
      return {
        dayKey: s.dayKey,
        date: s.date,
        doctorId,
        total: d ? d.total : 0,
        completed: d ? d.completed : 0,
        cancelled: d ? d.cancelled : 0,
        pending: d ? d.pending : 0,
      };
    });
  }

  return { data, count: data.length };
}

async function getByDay(rawDayKey) {
  const key = normalizeDayKey(rawDayKey);
  if (!key) throw ApiError.badRequest('dayKey must be a valid YYYY-MM-DD');
  const doc = await DailySummary.findById(key);
  return doc ? doc.toJSON() : null;
}

module.exports = { write, range, getByDay };
