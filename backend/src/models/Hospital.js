'use strict';

const mongoose = require('mongoose');

/**
 * Hospital / clinic. Ported from the patient app, minus device-relative fields
 * (distanceKm/lat/long are meaningless server-side). Kept lightweight; the only
 * field the appointment flow strictly needs is `name`, which is denormalized
 * onto each doctor.
 */
const hospitalSchema = new mongoose.Schema(
  {
    _id: { type: String }, // "h1".."h5"
    name: { type: String, required: true },
    address: { type: String },
    city: { type: String },
    phone: { type: String },
    imageUrl: { type: String },
    departments: { type: [String], default: [] },
    about: { type: String },
    openHours: { type: String },
  },
  { _id: false, timestamps: true }
);

module.exports = mongoose.model('Hospital', hospitalSchema);
