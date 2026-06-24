'use strict';

const User = require('../models/User');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../utils/asyncHandler');
const { signToken } = require('../middleware/auth');

// POST /api/auth/login
const login = asyncHandler(async (req, res) => {
  const { username, password } = req.body;
  const user = await User.findOne({ username: username.toLowerCase(), active: true });

  // Constant-ish response: don't reveal whether the username exists.
  if (!user || !(await user.verifyPassword(password))) {
    throw ApiError.unauthorized('Invalid username or password');
  }

  const token = signToken(user);
  res.json({
    token,
    role: user.role,
    displayName: user.displayName,
    userId: String(user._id),
  });
});

// GET /api/auth/me
const me = asyncHandler(async (req, res) => {
  res.json({ id: req.user.id, role: req.user.role, displayName: req.user.name });
});

module.exports = { login, me };
