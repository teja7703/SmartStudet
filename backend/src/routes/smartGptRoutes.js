const express = require('express');

const {
  getConversations,
  upsertConversation,
  deleteConversation,
  clearConversations,
} = require('../controllers/smartGptController');
const { requireUser } = require('../middleware/auth');

const router = express.Router();

router.use(requireUser);

router.get('/conversations', getConversations);
router.put('/conversations', upsertConversation);
router.delete('/conversations', clearConversations);
router.delete('/conversations/:id', deleteConversation);

module.exports = router;
