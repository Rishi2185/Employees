'use strict';

/**
 * Wrap an async route handler so thrown errors / rejected promises are forwarded
 * to Express's error middleware instead of crashing the process.
 */
module.exports = function asyncHandler(fn) {
  return function wrapped(req, res, next) {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
};
