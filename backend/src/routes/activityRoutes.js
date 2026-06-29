const express = require('express');

const {
  recordActivity,
  getActivity,
  clearActivity,
} = require('../controllers/activityController');
const { requireUser } = require('../middleware/auth');

const router = express.Router();

router.use(requireUser);

router.post('/', recordActivity);
router.get('/', getActivity);
router.delete('/', clearActivity);

module.exports = router;
