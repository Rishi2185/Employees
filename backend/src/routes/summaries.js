'use strict';

const express = require('express');
const validate = require('../middleware/validate');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ROLES } = require('../constants');
const { writeSchema, rangeQuerySchema } = require('../validators/summaryValidators');
const ctrl = require('../controllers/summaryController');

const router = express.Router();

const staff = requireRole(ROLES.ADMIN, ROLES.RECEPTION);

// End-of-day write — reception only.
router.post('/', requireAuth, requireRole(ROLES.RECEPTION), validate(writeSchema), ctrl.write);

// Historical reads — admin + reception.
router.get('/', requireAuth, staff, validate(rangeQuerySchema, 'query'), ctrl.range);
router.get('/:dayKey', requireAuth, staff, ctrl.getByDay);

module.exports = router;
