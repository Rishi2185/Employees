'use strict';

const crypto = require('crypto');
const mongoose = require('mongoose');
const {
  APPOINTMENT_STATUS,
  APPOINTMENT_STATUS_LABELS,
  PAYMENT_METHOD_LABELS,
  APPOINTMENT_SOURCE,
} = require('../constants');

// Backstop: anything more than this many seconds past its dateTime is auto-
// removed by MongoDB even if the end-of-day purge was missed. Future-dated
// appointments are never touched (TTL only fires once dateTime is in the past).
const TTL_BACKSTOP_SECONDS = 3 * 24 * 60 * 60; // 3 days

/**
 * Appointment — the rolling-window store (today + future only). Past days are
 * archived to the reception's local SQLite, summarized to DailySummary, then
 * purged from here.
 *
 * The first block of fields is a byte-for-byte superset of the patient app's
 * `Appointment.toJson()` so the patient app can adopt this API unchanged:
 * `status` and `paymentMethod` are stored as the patient enum's integer index.
 * The second block is reception/admin metadata — all optional or defaulted so
 * an anonymous patient-app booking still validates.
 */
const appointmentSchema = new mongoose.Schema(
  {
    _id: { type: String, default: () => `apt_${crypto.randomUUID()}` },

    // ── patient-app compatible fields ───────────────────────────────────────
    doctorId: { type: String, required: true },
    doctorName: { type: String, required: true },
    doctorPhotoUrl: { type: String, default: '' },
    specialtyName: { type: String, default: '' },
    hospitalName: { type: String, default: '' },
    dateTime: { type: Date, required: true },
    slotLabel: { type: String, required: true }, // "10:30 AM"
    fee: { type: Number, default: 0 },
    paymentMethod: { type: Number, default: 1 }, // 1 = UPI (patient enum index)
    status: {
      type: Number,
      enum: Object.values(APPOINTMENT_STATUS),
      default: APPOINTMENT_STATUS.UPCOMING,
    },
    reviewed: { type: Boolean, default: false },

    // ── reception / admin additions ─────────────────────────────────────────
    patientName: { type: String },
    patientPhone: { type: String },
    patientAge: { type: Number },
    patientGender: { type: String, enum: ['male', 'female', 'other'] },
    source: {
      type: String,
      enum: Object.values(APPOINTMENT_SOURCE),
      default: APPOINTMENT_SOURCE.PATIENT_APP,
    },
    checkedIn: { type: Boolean, default: false },
    tokenNumber: { type: Number },

    // Clinic-local calendar day (YYYY-MM-DD). Drives the rolling window, the
    // dashboard, and the end-of-day pull/summarize/purge.
    dayKey: { type: String, required: true, index: true },

    createdBy: { type: String }, // reception user id; null for patient bookings
  },
  { timestamps: true, _id: false }
);

// Dashboard + purge queries.
appointmentSchema.index({ dayKey: 1, doctorId: 1, status: 1 });
// Availability / slot-conflict scans.
appointmentSchema.index({ doctorId: 1, dateTime: 1 });
// Reception patient search.
appointmentSchema.index({ patientPhone: 1 });
// Hard double-booking guard: at most one UPCOMING appointment per
// doctor + day + slot. The app's isSlotBooked() is advisory; this is the truth.
appointmentSchema.index(
  { doctorId: 1, dayKey: 1, slotLabel: 1 },
  {
    unique: true,
    partialFilterExpression: { status: APPOINTMENT_STATUS.UPCOMING },
  }
);
// TTL backstop against a missed purge.
appointmentSchema.index({ dateTime: 1 }, { expireAfterSeconds: TTL_BACKSTOP_SECONDS });

// Emit the patient-compatible JSON shape: `id` (not `_id`), plus convenience
// string labels that the patient app harmlessly ignores.
appointmentSchema.set('toJSON', {
  transform(_doc, ret) {
    ret.id = ret._id;
    delete ret._id;
    delete ret.__v;
    ret.statusLabel = APPOINTMENT_STATUS_LABELS[ret.status];
    ret.paymentMethodLabel = PAYMENT_METHOD_LABELS[ret.paymentMethod];
    return ret;
  },
});

module.exports = mongoose.model('Appointment', appointmentSchema);
module.exports.TTL_BACKSTOP_SECONDS = TTL_BACKSTOP_SECONDS;
