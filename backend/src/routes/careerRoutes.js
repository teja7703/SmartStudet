const express = require('express');

const {
  createCareer,
  getCareers,
  getCareerById,
  deleteCareer,
} = require('../controllers/careerController');

const router = express.Router();

router.post('/', createCareer);

router.get('/', getCareers);

router.get('/:id', getCareerById);

router.delete('/:id', deleteCareer);

module.exports = router;