const mongoose = require('mongoose');

const careerSchema = new mongoose.Schema(
  {
    careerName: {
      type: String,
      required: true,
    },

    description: {
      type: String,
      required: true,
    },

    requiredEducation: {
      type: String,
      required: true,
    },

    salaryRange: {
      type: String,
      default: '',
    },

    skills: {
      type: [String],
      default: [],
    },

    imageUrl: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Career', careerSchema);