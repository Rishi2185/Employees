'use strict';

const mongoose = require('mongoose');

/**
 * Canonical specialty reference (id + display name only).
 *
 * The patient app's `Specialty` also carries a Flutter IconData + Color, but
 * those are UI concerns resolved client-side via `Specialties.byId(id)`. The
 * backend stays UI-agnostic and stores ids/names only; clients map id -> icon.
 */
const specialtySchema = new mongoose.Schema(
  {
    _id: { type: String }, // e.g. "cardiology", "general"
    name: { type: String, required: true }, // e.g. "Cardiology", "General"
  },
  { _id: false, timestamps: true }
);

module.exports = mongoose.model('Specialty', specialtySchema);
