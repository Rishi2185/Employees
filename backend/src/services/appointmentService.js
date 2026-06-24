'use strict';

const Appointment = require('../models/Appointment');
const Doctor = require('../models/Doctor');
const DailySummary = require('../models/DailySummary');
const ApiError = require('../utils/apiError');
const { APPOINTMENT_STATUS, APPOINTMENT_SOURCE } = require('../constants');
const { dayKey, todayKey, normalizeDayKey } = require('../utils/dayKey');
const { parsePaging, envelope } = require('../utils/pagination');

/** GET /appointments — date/range/doctor/status/q/checkedIn filtering. */
async function list(query) {
  const filter = {};
  if (query.date) filter.dayKey = query.date;
  else if (query.from || query.to) {
    filter.dayKey = {};
    if (query.from) filter.dayKey.$gte = query.from;
    if (query.to) filter.dayKey.$lte = query.to;
  }
  if (query.doctorId) filter.doctorId = query.doctorId;
  if (typeof query.status === 'number') filter.status = query.status;
  if (query.checkedIn !== undefined) filter.checkedIn = query.checkedIn;
  if (query.q && query.q.trim()) {
    const rx = new RegExp(escapeRegex(query.q.trim()), 'i');
    filter.$or = [{ patientName: rx }, { patientPhone: rx }, { doctorName: rx }];
  }

  const paging = parsePaging(query);
  const [docs, total] = await Promise.all([
    Appointment.find(filter)
      .sort({ dateTime: 1 })
      .skip(paging.skip)
      .limit(paging.limit),
    Appointment.countDocuments(filter),
  ]);

  return envelope(docs.map((d) => d.toJSON()), paging, total);
}

async function getById(id) {
  const doc = await Appointment.findById(id);
  return doc ? doc.toJSON() : null;
}

/**
 * Create an appointment (patient booking or reception walk-in). Denormalized
 * doctor fields are taken from the source-of-truth Doctor record. Rejects
 * past-dated bookings (the store only holds today + future). The partial-unique
 * slot index is the real double-booking guard; we pre-check for a nicer error.
 */
async function create(payload, { source, createdBy } = {}) {
  const doctor = await Doctor.findById(payload.doctorId).lean();
  if (!doctor) throw ApiError.badRequest('Unknown doctorId');
  if (doctor.active === false) throw ApiError.badRequest('Doctor is not active');

  const when = payload.dateTime;
  const key = dayKey(when);
  if (key < todayKey()) {
    throw ApiError.badRequest('Cannot book an appointment in a past day');
  }

  const doc = {
    doctorId: doctor._id,
    doctorName: doctor.name,
    doctorPhotoUrl: doctor.photoUrl,
    specialtyName: doctor.specialtyName,
    hospitalName: doctor.hospitalName,
    dateTime: when,
    slotLabel: payload.slotLabel,
    fee: payload.fee != null ? payload.fee : doctor.consultationFee,
    paymentMethod: payload.paymentMethod != null ? payload.paymentMethod : 1,
    status: APPOINTMENT_STATUS.UPCOMING,
    reviewed: false,
    patientName: payload.patientName,
    patientPhone: payload.patientPhone,
    patientAge: payload.patientAge,
    patientGender: payload.patientGender,
    tokenNumber: payload.tokenNumber,
    source: source || APPOINTMENT_SOURCE.PATIENT_APP,
    dayKey: key,
    createdBy: createdBy || undefined,
  };
  if (payload.id) doc._id = payload.id;

  // Friendly pre-check (advisory). The unique index handles the race.
  const clash = await Appointment.findOne({
    doctorId: doc.doctorId,
    dayKey: key,
    slotLabel: doc.slotLabel,
    status: APPOINTMENT_STATUS.UPCOMING,
  }).lean();
  if (clash) {
    throw ApiError.conflict('That slot is already booked for this doctor', {
      doctorId: doc.doctorId,
      dayKey: key,
      slotLabel: doc.slotLabel,
    });
  }

  const created = await Appointment.create(doc);
  return created.toJSON();
}

async function patch(id, changes) {
  const doc = await Appointment.findById(id);
  if (!doc) return null;
  Object.assign(doc, changes);
  await doc.save();
  return doc.toJSON();
}

async function remove(id) {
  const doc = await Appointment.findByIdAndDelete(id);
  return doc ? doc.toJSON() : null;
}

/** Printable appointment-slip payload. */
async function slip(id) {
  const doc = await Appointment.findById(id);
  if (!doc) return null;
  const a = doc.toJSON();
  return {
    appointmentId: a.id,
    tokenNumber: a.tokenNumber ?? null,
    patientName: a.patientName ?? null,
    patientPhone: a.patientPhone ?? null,
    doctorName: a.doctorName,
    specialtyName: a.specialtyName,
    hospitalName: a.hospitalName,
    dateTime: a.dateTime,
    slotLabel: a.slotLabel,
    fee: a.fee,
    statusLabel: a.statusLabel,
    generatedAt: new Date().toISOString(),
  };
}

/**
 * End-of-day purge of a completed day's full records. Safety-gated:
 *   - `confirm` must equal the dayKey (fat-finger guard);
 *   - the day must be strictly in the past (never purge today/future);
 *   - a DailySummary for that day MUST already exist (so we never delete full
 *     records that were not summarized first).
 * Idempotent: purging an already-empty day returns { deleted: 0 }.
 */
async function purgeDay(rawDayKey, confirm) {
  const key = normalizeDayKey(rawDayKey);
  if (!key) throw ApiError.badRequest('date must be a valid YYYY-MM-DD');
  if (confirm !== key) {
    throw ApiError.badRequest('confirm must equal the date being purged');
  }
  if (!(key < todayKey())) {
    throw ApiError.badRequest('Can only purge days strictly in the past');
  }

  const summary = await DailySummary.findById(key).lean();
  if (!summary) {
    throw ApiError.conflict(
      'Refusing to purge: no daily summary exists for this day yet. ' +
        'Write the summary (POST /api/summaries) before purging.'
    );
  }

  const result = await Appointment.deleteMany({ dayKey: key });
  return { dayKey: key, deleted: result.deletedCount || 0 };
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = { list, getById, create, patch, remove, slip, purgeDay };
