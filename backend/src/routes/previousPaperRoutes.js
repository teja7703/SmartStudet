const express = require('express');

const {
  createPreviousPaper,
  getPreviousPapers,
  getPreviousPaperById,
  deletePreviousPaper,
} = require('../controllers/previousPaperController');

const router = express.Router();

router.post('/', createPreviousPaper);

router.get('/', getPreviousPapers);

router.get('/:id', getPreviousPaperById);

router.delete('/:id', deletePreviousPaper);

module.exports = router;