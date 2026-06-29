const express = require('express');

const {
  loginUser,
  updateProfile,
  getMe,
} = require('../controllers/authController');
const { attachUser, requireUser } = require('../middleware/auth');

const router = express.Router();

router.post('/login', attachUser, loginUser);
router.put('/profile', attachUser, updateProfile);
router.get('/me', requireUser, getMe);

module.exports = router;
