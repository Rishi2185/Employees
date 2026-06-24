'use strict';

const appointmentService = require('../services/appointmentService');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { ROLES, APPOINTMENT_SOURCE } = require('../constants');
const {
  patientBookingSchema,
  receptionBookingSchema,
} = require('../validators/appointmentValidators');

// GET /api/appointments
const list = asyncHandler(async (req, res) => {
  res.json(await appointmentService.list(req.validatedQuery));
});

// GET /api/appointments/:id
const getById = asyncHandler(async (req, res) => {
  const doc = await appointmentService.getById(req.params.id);
  if (!doc) throw ApiError.notFound('Appointment not found');
  res.json(doc);
});

// GET /api/appointments/:id/slip
const slip = asyncHandler(async (req, res) => {
  const result = await appointmentService.slip(req.params.id);
  if (!result) throw ApiError.notFound('Appointment not found');
  res.json(result);
});

/**
 * POST /api/appointments
 * Schema chosen by caller: a reception user must supply patient name + phone
 * (walk-in); an anonymous/patient-app caller may book without identity.
 */
const create = asyncHandler(async (req, res) => {
  const isReception = req.user && req.user.role === ROLES.RECEPTION;
  const schema = isReception ? receptionBookingSchema : patientBookingSchema;

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    throw ApiError.badRequest('Validation failed', formatIssues(parsed.error));
  }

  const source = isReception
    ? APPOINTMENT_SOURCE.RECEPTION_WALKIN
    : APPOINTMENT_SOURCE.PATIENT_APP;

  const appt = await appointmentService.create(parsed.data, {
    source,
    createdBy: req.user ? req.user.id : undefined,
  });
  res.status(201).json(appt);
});

// PATCH /api/appointments/:id (reception)
const patch = asyncHandler(async (req, res) => {
  const doc = await appointmentService.patch(req.params.id, req.body);
  if (!doc) throw ApiError.notFound('Appointment not found');
  res.json(doc);
});

// DELETE /api/appointments/:id (reception) — manual cancel/remove
const remove = asyncHandler(async (req, res) => {
  const doc = await appointmentService.remove(req.params.id);
  if (!doc) throw ApiError.notFound('Appointment not found');
  res.json({ id: doc.id, deleted: true });
});

// DELETE /api/appointments?date=YYYY-MM-DD&confirm=YYYY-MM-DD (reception) — EOD purge
const purge = asyncHandler(async (req, res) => {
  const { date, confirm } = req.validatedQuery;
  res.json(await appointmentService.purgeDay(date, confirm));
});

function formatIssues(error) {
  return error.issues.map((i) => ({ path: i.path.join('.'), message: i.message }));
}

module.exports = { list, getById, slip, create, patch, remove, purge };
