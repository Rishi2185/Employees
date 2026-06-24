'use strict';

const jwt = require('jsonwebtoken');
const env = require('../config/env');
const ApiError = require('../utils/apiError');

/** Sign a JWT for a user. No PII in the token — id, role, name only. */
function signToken(user) {
  return jwt.sign(
    { sub: String(user._id), role: user.role, name: user.displayName },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );
}

/** Extract and verify the Bearer token; attach `req.user`. Throws 401 on fail. */
function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return next(ApiError.unauthorized('Missing or malformed Authorization header'));
  }
  try {
    const payload = jwt.verify(token, env.jwtSecret);
    req.user = { id: payload.sub, role: payload.role, name: payload.name };
    return next();
  } catch (_err) {
    return next(ApiError.unauthorized('Invalid or expired token'));
  }
}

/** Require one of the given roles. Use after requireAuth. */
function requireRole(...roles) {
  return function roleGuard(req, _res, next) {
    if (!req.user) return next(ApiError.unauthorized());
    if (!roles.includes(req.user.role)) {
      return next(ApiError.forbidden('Insufficient role for this action'));
    }
    return next();
  };
}

/**
 * Attach `req.user` if a valid token is present, but don't require it. Lets
 * endpoints (e.g. doctors list) serve public reads while still recognizing
 * authenticated callers.
 */
function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme === 'Bearer' && token) {
    try {
      const payload = jwt.verify(token, env.jwtSecret);
      req.user = { id: payload.sub, role: payload.role, name: payload.name };
    } catch (_err) {
      /* ignore — treated as anonymous */
    }
  }
  return next();
}

module.exports = { signToken, requireAuth, requireRole, optionalAuth };
