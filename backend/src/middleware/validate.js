'use strict';

const ApiError = require('../utils/apiError');

/**
 * Build a middleware that validates a request part against a zod schema and
 * replaces it with the parsed (coerced, stripped) value.
 *
 * @param {import('zod').ZodTypeAny} schema
 * @param {'body'|'query'|'params'} part
 */
function validate(schema, part = 'body') {
  return function validator(req, _res, next) {
    const result = schema.safeParse(req[part]);
    if (!result.success) {
      const details = result.error.issues.map((i) => ({
        path: i.path.join('.'),
        message: i.message,
      }));
      return next(ApiError.badRequest('Validation failed', details));
    }
    // req.query/params getters can be read-only on some Express versions; assign
    // the parsed result onto a parallel field the handlers read from.
    if (part === 'query') req.validatedQuery = result.data;
    else if (part === 'params') req.validatedParams = result.data;
    else req.body = result.data;
    return next();
  };
}

module.exports = validate;
