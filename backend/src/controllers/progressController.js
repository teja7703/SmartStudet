const QuizResult = require('../models/QuizResult');
const Activity = require('../models/Activity');
const User = require('../models/User');

// Number of distinct consecutive days (ending today or yesterday) that the
// user has any quiz/activity on. Mirrors the previous Flutter logic.
function computeStreak(dates) {
  const days = new Set(
    dates.map((d) => {
      const dt = new Date(d);
      return `${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`;
    })
  );
  if (days.size === 0) return 0;

  const key = (dt) => `${dt.getFullYear()}-${dt.getMonth()}-${dt.getDate()}`;
  let cursor = new Date();
  cursor.setHours(0, 0, 0, 0);

  if (!days.has(key(cursor))) {
    cursor.setDate(cursor.getDate() - 1);
    if (!days.has(key(cursor))) return 0;
  }

  let streak = 0;
  while (days.has(key(cursor))) {
    streak += 1;
    cursor.setDate(cursor.getDate() - 1);
  }
  return streak;
}

function percentage(correct, total) {
  return total > 0 ? Math.round((correct / total) * 100) : 0;
}

// Recomputes a user's derived points + streak from their stored results and
// activities and persists them on the User document.
async function syncUserStats(firebaseUid) {
  const [results, activities] = await Promise.all([
    QuizResult.find({ firebaseUid }).lean(),
    Activity.find({ firebaseUid }).lean(),
  ]);

  const points = results.reduce((s, r) => s + (r.pointsEarned || 0), 0);
  const streak = computeStreak([
    ...results.map((r) => r.date || r.createdAt),
    ...activities.map((a) => a.updatedAt || a.createdAt),
  ]);

  await User.findOneAndUpdate({ firebaseUid }, { points, streak });
  return { points, streak, results, activities };
}

const saveQuizResult = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const body = req.body || {};

    const result = await QuizResult.create({
      firebaseUid,
      quizId: body.quizId,
      title: body.title,
      subject: body.subject,
      classLevel: body.classLevel,
      total: body.total,
      correct: body.correct,
      pointsEarned: body.pointsEarned,
      totalPoints: body.totalPoints,
      timeTakenSeconds: body.timeTakenSeconds,
      date: body.date ? new Date(body.date) : new Date(),
      answers: Array.isArray(body.answers) ? body.answers : [],
    });

    const { points, streak } = await syncUserStats(firebaseUid);

    console.log(
      `[QUIZ] saved _id=${result._id} uid=${firebaseUid} subject=${result.subject} ` +
        `score=${result.correct}/${result.total} points=${points} streak=${streak}`
    );

    res.status(201).json({ success: true, data: result, points, streak });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getQuizHistory = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const results = await QuizResult.find({ firebaseUid })
      .sort({ date: -1 })
      .limit(50)
      .lean();

    console.log(`[QUIZ] history uid=${firebaseUid} count=${results.length}`);
    res.status(200).json({ success: true, data: results });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const clearQuizHistory = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    await QuizResult.deleteMany({ firebaseUid });
    await syncUserStats(firebaseUid);
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getProgress = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;

    const [results, activities] = await Promise.all([
      QuizResult.find({ firebaseUid }).sort({ date: -1 }).lean(),
      Activity.find({ firebaseUid }).sort({ updatedAt: -1 }).lean(),
    ]);

    const quizzesCompleted = results.length;
    const pointsEarned = results.reduce(
      (s, r) => s + (r.pointsEarned || 0),
      0
    );
    const avgScore =
      quizzesCompleted === 0
        ? 0
        : Math.round(
            results.reduce((s, r) => s + percentage(r.correct, r.total), 0) /
              quizzesCompleted
          );
    const bestScore = results.reduce(
      (b, r) => Math.max(b, percentage(r.correct, r.total)),
      0
    );

    let materialsViewed = 0;
    let storiesRead = 0;
    for (const a of activities) {
      if (a.type === 'material') materialsViewed += 1;
      if (a.type === 'story') storiesRead += 1;
    }

    const streak = computeStreak([
      ...results.map((r) => r.date || r.createdAt),
      ...activities.map((a) => a.updatedAt || a.createdAt),
    ]);

    const recent = [
      ...results.map((r) => ({
        type: 'quiz',
        title: `${r.subject} Quiz`,
        subtitle: `${percentage(r.correct, r.total)}% • ${r.correct}/${r.total} correct`,
        route: '/quizzes/history',
        date: r.date || r.createdAt,
      })),
      ...activities.map((a) => ({
        type: a.type,
        title: a.title || '',
        subtitle: a.subtitle || '',
        route: a.type === 'story' ? `/stories/${a.refId}` : '/study-materials',
        date: a.updatedAt || a.createdAt,
      })),
    ]
      .sort((x, y) => new Date(y.date) - new Date(x.date))
      .slice(0, 8);

    // Keep the User document's points/streak in sync on every read too.
    await User.findOneAndUpdate({ firebaseUid }, { points: pointsEarned, streak });

    console.log(
      `[PROGRESS] uid=${firebaseUid} quizzes=${quizzesCompleted} points=${pointsEarned} ` +
        `streak=${streak} materials=${materialsViewed} stories=${storiesRead}`
    );

    res.status(200).json({
      success: true,
      data: {
        quizzesCompleted,
        pointsEarned,
        avgScore,
        bestScore,
        streak,
        materialsViewed,
        storiesRead,
        recent,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  saveQuizResult,
  getQuizHistory,
  clearQuizHistory,
  getProgress,
  syncUserStats,
};
