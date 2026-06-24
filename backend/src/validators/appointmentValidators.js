'use strict';

const { z } = require('zod');
const { APPOINTMENT_STATUS, PAYMENT_METHOD } = require('../constants');

const statusInt = z.coerce
  .number()
  .int()
  .refine((v) => Object.values(APPOINTMENT_STATUS).includes(v), {
    message: 'status must be 0 (upcoming), 1 (completed) or 2 (cancelled)',
  });

const paymentInt = z.coerce
  .number()
  .int()
  .refine((v) => Object.values(PAYMENT_METHOD).includes(v), {
    message: 'paymentMethod must be 0 (card), 1 (upi) or 2 (wallet)',
  });

const dayKeyStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'expected YYYY-MM-DD');

// Fields common to any booking. Denormalized doctor fields are derived
// server-side from the doctor record, so they are NOT accepted from the client.
const baseBooking = {
  id: z.string().trim().min(1).optional(), // accept a client-supplied id
  doctorId: z.string().trim().min(1),
  dateTime: z.coerce.date(),
  slotLabel: z.string().trim().min(1),
  fee: z.number().int().min(0).optional(),
  paymentMethod: paymentInt.optional(),
  patientAge: z.number().int().min(0).max(130).optional(),
  patientGender: z.enum(['male', 'female', 'other']).optional(),
};

// Patient-app booking — identity is optional (the app has no patient record).
const patientBookingSchema = z
  .object({
    ...baseBooking,
    patientName: z.string().trim().optional(),
    patientPhone: z.string().trim().optional(),
  })
  .strip(); // tolerate extra patient-app keys (doctorName, status, reviewed, ...)

// Reception walk-in / desk booking — name + phone are required.
const receptionBookingSchema = z
  .object({
    ...baseBooking,
    patientName: z.string().trim().min(1, 'patient name is required'),
    patientPhone: z.string().trim().min(3, 'patient phone is required'),
    tokenNumber: z.number().int().min(0).optional(),
  })
  .strict();

// PATCH /appointments/:id
const patchSchema = z
  .object({
    status: statusInt.optional(),
    checkedIn: z.boolean().optional(),
    reviewed: z.boolean().optional(),
    patientName: z.string().trim().optional(),
    patientPhone: z.string().trim().optional(),
    patientAge: z.number().int().min(0).max(130).optional(),
    patientGender: z.enum(['male', 'female', 'other']).optional(),
    tokenNumber: z.number().int().min(0).optional(),
  })
  .strict()
  .refine((o) => Object.keys(o).length > 0, {
    message: 'At least one field must be provided',
  });

// GET /appointments
const listQuerySchema = z
  .object({
    date: dayKeyStr.optional(),
    from: dayKeyStr.optional(),
    to: dayKeyStr.optional(),
    doctorId: z.string().trim().optional(),
    status: statusInt.optional(),
    q: z.string().trim().optional(),
    checkedIn: z
      .enum(['true', 'false'])
      .optional()
      .transform((v) => (v === undefined ? undefined : v === 'true')),
    page: z.coerce.number().int().min(1).optional(),
    limit: z.coerce.number().int().min(1).max(100).optional(),
  })
  .strip();

// DELETE /appointments (end-of-day purge) — both params required for safety.
const purgeQuerySchema = z
  .object({
    date: dayKeyStr,
    confirm: z.string(),
  })
  .strip();

module.exports = {
  patientBookingSchema,
  receptionBookingSchema,
  patchSchema,
  listQuerySchema,
  purgeQuerySchema,
};
