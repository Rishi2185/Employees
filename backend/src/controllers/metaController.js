'use strict';

const Specialty = require('../models/Specialty');
const Hospital = require('../models/Hospital');
const asyncHandler = require('../utils/asyncHandler');

// GET /api/specialties — canonical list (id + name). Clients map id -> icon/color.
const specialties = asyncHandler(async (_req, res) => {
  const docs = await Specialty.find().sort({ name: 1 }).lean();
  res.json({ data: docs.map((d) => ({ id: d._id, name: d.name })) });
});

// GET /api/hospitals
const hospitals = asyncHandler(async (_req, res) => {
  const docs = await Hospital.find().sort({ name: 1 }).lean();
  res.json({ data: docs.map(({ _id, __v, ...rest }) => ({ id: _id, ...rest })) });
});

module.exports = { specialties, hospitals };
