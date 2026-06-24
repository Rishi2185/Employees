'use strict';

const express = require('express');
const validate = require('../middleware/validate');
const { requireAuth, requireRole, optionalAuth } = require('../middleware/auth');
const { ROLES } = require('../constants');
const {
  listQuerySchema,
  patchSchema,
  purgeQuerySchema,
} = require('../validators/appointmentValidators');
const ctrl = require('../controllers/appointmentController');

const router = express.Router();

const staff = requireRole(ROLES.ADMIN, ROLES.RECEPTION);

// Reads — reception + admin.
router.get('/', requireAuth, staff, validate(listQuerySchema, 'query'), ctrl.list);

// End-of-day purge — reception only. Declared before '/:id' for clarity (paths
// differ, so order is not strictly required).
router.delete(
  '/',
  requireAuth,
  requireRole(ROLES.RECEPTION),
  validate(purgeQuerySchema, 'query'),
  ctrl.purge
);

// Create — reception (walk-in, requires identity) or anonymous patient booking.
router.post('/', optionalAuth, ctrl.create);

router.get('/:id', requireAuth, staff, ctrl.getById);
router.get('/:id/slip', requireAuth, staff, ctrl.slip);
router.patch('/:id', requireAuth, staff, validate(patchSchema), ctrl.patch);
router.delete('/:id', requireAuth, staff, ctrl.remove);

module.exports = router;
