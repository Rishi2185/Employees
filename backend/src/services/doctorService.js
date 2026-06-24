'use strict';

const Doctor = require('../models/Doctor');
const Appointment = require('../models/Appointment');
const { APPOINTMENT_STATUS } = require('../constants');
const { parsePaging, envelope } = require('../utils/pagination');

// Sort specs mirror the patient app's DoctorProvider exactly:
// relevance == ratingHigh == rating desc.
const SORT_SPECS = {
  relevance: { rating: -1 },
  ratingHigh: { rating: -1 },
  feeLow: { consultationFee: 1 },
  feeHigh: { consultationFee: -1 },
  experience: { experienceYears: -1 },
};

/** List doctors with the patient app's q/specialtyId/availableToday/minRating/sort. */
async function list(query) {
  const filter = {};
  if (!query.includeInactive) filter.active = true;
  if (query.specialtyId) filter.specialtyId = query.specialtyId;
  if (query.availableToday !== undefined) filter.availableToday = query.availableToday;
  if (typeof query.minRating === 'number') filter.rating = { $gte: query.minRating };

  if (query.q && query.q.trim()) {
    // Case-insensitive match across name / specialtyName / qualifications,
    // mirroring DoctorProvider.doctors().
    const rx = new RegExp(escapeRegex(query.q.trim()), 'i');
    filter.$or = [{ name: rx }, { specialtyName: rx }, { qualifications: rx }];
  }

  const sort = SORT_SPECS[query.sort] || SORT_SPECS.relevance;
  const paging = parsePaging(query);

  const [data, total] = await Promise.all([
    Doctor.find(filter).sort(sort).skip(paging.skip).limit(paging.limit).lean(),
    Doctor.countDocuments(filter),
  ]);

  return envelope(data.map(withId), paging, total);
}

async function getById(id) {
  const doc = await Doctor.findById(id).lean();
  return doc ? withId(doc) : null;
}

async function create(payload) {
  const doc = await Doctor.create(payload);
  return withId(doc.toObject());
}

async function update(id, patch) {
  const doc = await Doctor.findByIdAndUpdate(id, patch, {
    new: true,
    runValidators: true,
  }).lean();
  return doc ? withId(doc) : null;
}

/** Soft-delete: mark inactive so historical appointments still resolve the name. */
async function softDelete(id) {
  const doc = await Doctor.findByIdAndUpdate(
    id,
    { active: false },
    { new: true }
  ).lean();
  return doc ? withId(doc) : null;
}

/**
 * Availability for a given day: the doctor's window + days, plus the slots
 * already taken (upcoming appointments) so a client can grey them out. Slot
 * generation itself stays client-side to match the patient app's SlotGenerator.
 */
async function availability(id, dayKey) {
  const doc = await Doctor.findById(id).lean();
  if (!doc) return null;

  const bookedSlots = dayKey
    ? (
        await Appointment.find({
          doctorId: id,
          dayKey,
          status: APPOINTMENT_STATUS.UPCOMING,
        })
          .select('slotLabel')
          .lean()
      ).map((a) => a.slotLabel)
    : [];

  return {
    doctorId: id,
    availableDays: doc.availableDays,
    consultStart: doc.consultStart,
    consultEnd: doc.consultEnd,
    availableToday: doc.availableToday,
    dayKey: dayKey || null,
    bookedSlots,
  };
}

function withId(doc) {
  const { _id, __v, ...rest } = doc;
  return { id: _id, ...rest };
}

function escapeRegex(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

module.exports = { list, getById, create, update, softDelete, availability };
