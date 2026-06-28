'use strict';

const express = require('express');
const ImageKit = require('imagekit');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ROLES } = require('../constants');
const env = require('../config/env');

const router = express.Router();

// Lazily initialised — only created when the first request comes in, so the
// server still boots fine if the keys are blank (dev/demo without uploads).
let _ik;
function ik() {
  if (!_ik) {
    const { publicKey, privateKey, urlEndpoint } = env.imagekit;
    if (!publicKey || !privateKey || !urlEndpoint) {
      throw new Error(
        'ImageKit credentials are not configured. Set IMAGEKIT_PUBLIC_KEY, ' +
          'IMAGEKIT_PRIVATE_KEY, and IMAGEKIT_URL_ENDPOINT in your .env file.'
      );
    }
    _ik = new ImageKit({ publicKey, privateKey, urlEndpoint });
  }
  return _ik;
}

// GET /api/imagekit/auth — returns { token, expire, signature } for a
// client-side upload. Admin-only so random users can't burn your quota.
router.get('/auth', requireAuth, requireRole(ROLES.ADMIN), (_req, res, next) => {
  try {
    const params = ik().getAuthenticationParameters();
    res.json(params);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
