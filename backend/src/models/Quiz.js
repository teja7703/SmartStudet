const mongoose = require('mongoose');

const quizSchema = new mongoose.Schema(
  {
    question: {
      type: String,
      required: true,
    },

    options: {
      type: [String],
      required: true,
      validate: {
        validator: (options) => options.length === 4,
        message: 'Quiz must have exactly 4 options',
      },
    },

    correctAnswer: {
      type: String,
      required: true,
    },

    explanation: {
      type: String,
      default: '',
    },

    category: {
      type: String,
      required: true,
    },

    classLevel: {
      type: String,
      required: true,
    },

    // Language the question is written in. Legacy questions have no value and
    // are treated as English.
    language: {
      type: String,
      enum: ['English', 'Telugu'],
      default: 'English',
    },

    difficulty: {
      type: String,
      enum: ['Easy', 'Medium', 'Hard'],
      default: 'Easy',
    },

    points: {
      type: Number,
      default: 10,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Quiz', quizSchema);