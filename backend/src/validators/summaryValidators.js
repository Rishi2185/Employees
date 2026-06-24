'use strict';

const { z } = require('zod');

const dayKeyStr = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'expected YYYY-MM-DD');

// POST /summaries — reception supplies only the day; the server computes counts.
const writeSchema = z
  .object({
    dayKey: dayKeyStr,
  })
  .strict();

// GET /summaries?from&to&doctorId
const rangeQuerySchema = z
  .object({
    from: dayKeyStr.optional(),
    to: dayKeyStr.optional(),
    doctorId: z.string().trim().optional(),
  })
  .strip();

module.exports = { writeSchema, rangeQuerySchema };
