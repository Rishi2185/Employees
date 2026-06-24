'use strict';

const { z } = require('zod');

const SORTS = ['relevance', 'ratingHigh', 'feeLow', 'feeHigh', 'experience'];

// GET /doctors — mirrors the patient app's DoctorProvider params.
const listQuerySchema = z
  .object({
    q: z.string().trim().optional(),
    specialtyId: z.string().trim().optional(),
    availableToday: z
      .enum(['true', 'false'])
      .optional()
      .transform((v) => (v === undefined ? undefined : v === 'true')),
    minRating: z.coerce.number().min(0).max(5).optional(),
    sort: z.enum(SORTS).optional().default('relevance'),
    includeInactive: z
      .enum(['true', 'false'])
      .optional()
      .transform((v) => v === 'true'),
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(100).optional(),
  })
  .strip();

// POST /doctors (admin) — full create. _id optional (auto if omitted).
const createSchema = z
  .object({
    _id: z.string().trim().min(1).optional(),
    name: z.string().trim().min(1),
    specialtyId: z.string().trim().min(1),
    specialtyName: z.string().trim().min(1),
    qualifications: z.string().default(''),
    experienceYears: z.number().int().min(0).default(0),
    rating: z.number().min(0).max(5).default(0),
    reviewCount: z.number().int().min(0).default(0),
    consultationFee: z.number().int().min(0).default(0),
    about: z.string().default(''),
    photoUrl: z.string().default(''),
    hospitalId: z.string().optional(),
    hospitalName: z.string().default(''),
    languages: z.array(z.string()).default([]),
    patientsServed: z.number().int().min(0).default(0),
    consultStart: z.string().default('09:00'),
    consultEnd: z.string().default('17:00'),
    availableDays: z.array(z.string()).default([]),
    availableToday: z.boolean().default(false),
    active: z.boolean().default(true),
  })
  .strict();

// PATCH /doctors/:id (admin) — all fields optional; at least one required.
// `_id` is immutable, so it's omitted from the updatable set.
const updateSchema = createSchema
  .omit({ _id: true })
  .partial()
  .strict()
  .refine((obj) => Object.keys(obj).length > 0, {
    message: 'At least one field must be provided',
  });

module.exports = { listQuerySchema, createSchema, updateSchema, SORTS };
