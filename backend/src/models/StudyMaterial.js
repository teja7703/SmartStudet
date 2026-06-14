const mongoose = require('mongoose');

const studyMaterialSchema = new mongoose.Schema(
  {
    academicLevel: {
      type: String,
      required: true,
    },

    subject: {
      type: String,
      required: true,
    },

    chapter: {
      type: String,
      required: true,
    },

    title: {
      type: String,
      required: true,
    },

    content: {
      type: String,
      required: true,
    },

    pdfUrl: {
      type: String,
      default: '',
    },

    videoUrl: {
      type: String,
      default: '',
    },

    language: {
      type: String,
      default: 'English',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  'StudyMaterial',
  studyMaterialSchema
);