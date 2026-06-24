'use strict';

const mongoose = require('mongoose');

/**
 * One tiny aggregate document per clinic day. Written by the reception app at
 * end-of-day, read by the admin app for historical trends. COUNTS ONLY — no
 * patient PII — so years of history fit comfortably on the Atlas free tier and
 * the cloud holds no personal data for past days (those live only in the
 * reception's local SQLite archive).
 *
 * `_id` is the dayKey itself, which makes the end-of-day write an idempotent
 * upsert (re-running it overwrites the same doc, never duplicates).
 */
const perDoctorSchema = new mongoose.Schema(
  {
    doctorId: { type: String, required: true },
    doctorName: { type: String, required: true },
    total: { type: Number, default: 0 },
    completed: { type: Number, default: 0 },
    cancelled: { type: Number, default: 0 },
    pending: { type: Number, default: 0 },
  },
  { _id: false }
);

const overallSchema = new mongoose.Schema(
  {
    total: { type: Number, default: 0 },
    completed: { type: Number, default: 0 },
    cancelled: { type: Number, default: 0 },
    pending: { type: Number, default: 0 },
    walkIns: { type: Number, default: 0 },
    revenue: { type: Number, default: 0 }, // sum of fee for completed visits
  },
  { _id: false }
);

const dailySummarySchema = new mongoose.Schema(
  {
    _id: { type: String }, // dayKey "YYYY-MM-DD"
    date: { type: Date, required: true },
    overall: { type: overallSchema, default: () => ({}) },
    perDoctor: { type: [perDoctorSchema], default: [] },
    generatedAt: { type: Date, default: Date.now },
    generatedBy: { type: String }, // reception user id
    version: { type: Number, default: 1 },
  },
  { _id: false }
);

dailySummarySchema.set('toJSON', {
  transform(_doc, ret) {
    ret.dayKey = ret._id;
    delete ret._id;
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('DailySummary', dailySummarySchema);
