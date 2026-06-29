const express = require('express');

const {
  saveQuizResult,
  getQuizHistory,
  clearQuizHistory,
  getProgress,
  getQuizStats,
} = require('../controllers/progressController');
const { requireUser } = require('../middleware/auth');

const router = express.Router();

// All progress endpoints are scoped to the authenticated user.
router.use(requireUser);

// Aggregated stats (points, streak, averages, recent activity).
router.get('/', getProgress);

// Per-subject quiz stats (completed questions, best/avg score) for a class.
router.get('/quiz-stats', getQuizStats);

// Quiz history (per user).
router.post('/quiz-results', saveQuizResult);
router.get('/quiz-results', getQuizHistory);
router.delete('/quiz-results', clearQuizHistory);

module.exports = router;
