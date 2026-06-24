'use strict';

const doctorService = require('../services/doctorService');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { normalizeDayKey } = require('../utils/dayKey');

// GET /api/doctors
const list = asyncHandler(async (req, res) => {
  res.json(await doctorService.list(req.validatedQuery));
});

// GET /api/doctors/:id
const getById = asyncHandler(async (req, res) => {
  const doc = await doctorService.getById(req.params.id);
  if (!doc) throw ApiError.notFound('Doctor not found');
  res.json(doc);
});

// GET /api/doctors/:id/availability?date=YYYY-MM-DD
const availability = asyncHandler(async (req, res) => {
  const dayKey = req.query.date ? normalizeDayKey(req.query.date) : null;
  if (req.query.date && !dayKey) throw ApiError.badRequest('date must be YYYY-MM-DD');
  const result = await doctorService.availability(req.params.id, dayKey);
  if (!result) throw ApiError.notFound('Doctor not found');
  res.json(result);
});

// POST /api/doctors (admin)
const create = asyncHandler(async (req, res) => {
  const doc = await doctorService.create(req.body);
  res.status(201).json(doc);
});

// PATCH /api/doctors/:id (admin)
const update = asyncHandler(async (req, res) => {
  const doc = await doctorService.update(req.params.id, req.body);
  if (!doc) throw ApiError.notFound('Doctor not found');
  res.json(doc);
});

// DELETE /api/doctors/:id (admin) — soft delete
const remove = asyncHandler(async (req, res) => {
  const doc = await doctorService.softDelete(req.params.id);
  if (!doc) throw ApiError.notFound('Doctor not found');
  res.json({ id: doc.id, active: doc.active });
});

module.exports = { list, getById, availability, create, update, remove };
