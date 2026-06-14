const mongoose = require('mongoose');

const previousPaperSchema = new mongoose.Schema(
  {
    academicLevel: {
      type: String,
      required: true,
    },

    subject: {
      type: String,
      required: true,
    },

    year: {
      type: Number,
      required: true,
    },

    paperType: {
      type: String,
      default: 'Public Exam',
    },

    pdfUrl: {
      type: String,
      required: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model(
  'PreviousPaper',
  previousPaperSchema
);