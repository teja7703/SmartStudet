const express = require('express');

const {
  createStory,
  getStories,
  getStoryById,
  deleteStory,
} = require('../controllers/storyController');

const router = express.Router();

router.post('/', createStory);

router.get('/', getStories);

router.get('/:id', getStoryById);

router.delete('/:id', deleteStory);

module.exports = router;