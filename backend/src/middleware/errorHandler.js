'use strict';

const env = require('../config/env');
const ApiError = require('../utils/apiError');

/** 404 for unmatched routes. */
function notFoundHandler(req, _res, next) {
  next(ApiError.notFound(`Route not found: ${req.method} ${req.originalUrl}`));
}

/* eslint-disable no-unused-vars */
/** Central error handler. Maps known error types to clean JSON responses. */
function errorHandler(err, _req, res, _next) {
  let status = err.status || 500;
  let message = err.message || 'Internal server error';
  let details = err.details;

  // Mongo duplicate key (e.g. the partial-unique slot index) -> 409 conflict.
  if (err.code === 11000) {
    status = 409;
    message = 'Resource already exists or slot is already booked';
    details = err.keyValue;
  }

  // Mongoose validation / cast errors -> 400.
  if (err.name === 'ValidationError') {
    status = 400;
    message = 'Validation failed';
    details = Object.values(err.errors || {}).map((e) => ({
      path: e.path,
      message: e.message,
    }));
  }
  if (err.name === 'CastError') {
    status = 400;
    message = `Invalid value for "${err.path}"`;
  }

  if (status >= 500 && !env.isTest) {
    console.error('[error]', err);
  }

  const payload = { error: message };
  if (details) payload.details = details;
  if (!env.isProd && status >= 500) payload.stack = err.stack;

  res.status(status).json(payload);
}

module.exports = { notFoundHandler, errorHandler };
