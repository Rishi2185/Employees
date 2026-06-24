'use strict';

const crypto = require('crypto');
const mongoose = require('mongoose');

/**
 * Doctor profile — the source of truth for the roster shown to patients.
 * Persistent; written only by admins. Ported field-for-field from the patient
 * app's `Doctor` model, with two structural changes:
 *   - `specialty` (a UI object) becomes `specialtyId` + `specialtyName` strings.
 *   - `hospitalName` is denormalized so booking an appointment is a single read
 *     (no $lookup — friendlier to the Atlas free tier).
 *
 * `_id` keeps the patient app's stable string ids ("d1".."d12") so any existing
 * references by doctorId stay valid.
 */
const doctorSchema = new mongoose.Schema(
  {
    // Seeded doctors keep their patient-app ids ("d1".."d12"); admin-created
    // doctors get a generated string id if none is supplied.
    _id: { type: String, default: () => `doc_${crypto.randomUUID()}` },
    name: { type: String, required: true },

    specialtyId: { type: String, required: true, index: true },
    specialtyName: { type: String, required: true },

    qualifications: { type: String, default: '' },
    experienceYears: { type: Number, default: 0 },
    rating: { type: Number, default: 0, min: 0, max: 5 },
    reviewCount: { type: Number, default: 0 },
    consultationFee: { type: Number, default: 0 }, // INR
    about: { type: String, default: '' },
    photoUrl: { type: String, default: '' },

    hospitalId: { type: String },
    hospitalName: { type: String, default: '' }, // denormalized

    languages: { type: [String], default: [] },
    patientsServed: { type: Number, default: 0 },

    // Opaque display strings ("09:00"). Not parsed into real time windows.
    consultStart: { type: String, default: '09:00' },
    consultEnd: { type: String, default: '17:00' },
    availableDays: { type: [String], default: [] }, // ["Mon","Tue",...]

    // Manually-owned "doctor is in today" toggle (reception/admin). The patient
    // app filters directly on this flag.
    availableToday: { type: Boolean, default: false },

    // Soft-delete: admin "remove" sets active=false rather than hard-deleting,
    // so historical appointments keep resolving the doctor name.
    active: { type: Boolean, default: true, index: true },
  },
  { _id: false, timestamps: true }
);

module.exports = mongoose.model('Doctor', doctorSchema);
