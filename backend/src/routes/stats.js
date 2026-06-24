'use strict';

const express = require('express');
const { requireAuth, requireRole } = require('../middleware/auth');
const { ROLES } = require('../constants');
const ctrl = require('../controllers/statsController');

const router = express.Router();

const staff = requireRole(ROLES.ADMIN, ROLES.RECEPTION);

router.get('/today', requireAuth, staff, ctrl.today);
router.get('/doctors', requireAuth, staff, ctrl.doctors);
router.get('/overview', requireAuth, staff, ctrl.overview);
router.get('/live', requireAuth, requireRole(ROLES.ADMIN), ctrl.live);

module.exports = router;
