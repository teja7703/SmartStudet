const express = require('express');

const {
  createStudyMaterial,
  getStudyMaterials,
  getStudyMaterialById,
  deleteStudyMaterial,
} = require('../controllers/studyMaterialController');

const router = express.Router();

router.post('/', createStudyMaterial);

router.get('/', getStudyMaterials);

router.get('/:id', getStudyMaterialById);

router.delete('/:id', deleteStudyMaterial);

module.exports = router;