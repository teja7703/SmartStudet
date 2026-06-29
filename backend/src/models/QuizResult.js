const mongoose = require('mongoose');

// A single answered/skipped question within an attempt. Mirrors the Flutter
// AnswerRecord model so the client can round-trip results unchanged.
const answerSchema = new mongoose.Schema(
  {
    question: String,
    options: [String],
    correctAnswer: String,
    selectedAnswer: String,
    explanation: String,
  },
  { _id: false }
);

// A completed quiz attempt, scoped to a single Firebase user.
const quizResultSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
    },
    quizId: String,
    title: String,
    subject: String,
    classLevel: String,
    total: { type: Number, default: 0 },
    correct: { type: Number, default: 0 },
    pointsEarned: { type: Number, default: 0 },
    totalPoints: { type: Number, default: 0 },
    timeTakenSeconds: { type: Number, default: 0 },
    date: { type: Date, default: Date.now },
    answers: [answerSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model('QuizResult', quizResultSchema);
