'use strict';

const express = require('express');
const validate = require('../middleware/validate');
const { requireAuth, requireRole, optionalAuth } = require('../middleware/auth');
const { ROLES } = require('../constants');
const { listQuerySchema, createSchema, updateSchema } = require('../validators/doctorValidators');
const ctrl = require('../controllers/doctorController');

const router = express.Router();

// Public reads (patient app + reception + admin).
router.get('/', optionalAuth, validate(listQuerySchema, 'query'), ctrl.list);
router.get('/:id', optionalAuth, ctrl.getById);
router.get('/:id/availability', optionalAuth, ctrl.availability);

// Admin-only writes (reflected in the patient app's roster).
router.post('/', requireAuth, requireRole(ROLES.ADMIN), validate(createSchema), ctrl.create);
router.patch('/:id', requireAuth, requireRole(ROLES.ADMIN), validate(updateSchema), ctrl.update);
router.delete('/:id', requireAuth, requireRole(ROLES.ADMIN), ctrl.remove);

module.exports = router;
