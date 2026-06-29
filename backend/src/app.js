const express = require('express');
const cors = require('cors');
require('dotenv').config();

const connectDB = require('./config/database');

const app = express();

connectDB();

app.use(cors());
app.use(express.json());

const userRoutes = require('./routes/userRoutes');
app.use('/api/users', userRoutes);

const storyRoutes = require('./routes/storyRoutes');
app.use('/api/stories', storyRoutes);

const careerRoutes = require('./routes/careerRoutes');
app.use('/api/careers', careerRoutes);

const quizRoutes = require('./routes/quizRoutes');
app.use('/api/quizzes', quizRoutes);

const studyMaterialRoutes =
  require('./routes/studyMaterialRoutes');

app.use(
  '/api/study-materials',
  studyMaterialRoutes
);

const previousPaperRoutes =
  require('./routes/previousPaperRoutes');

app.use(
  '/api/previous-papers',
  previousPaperRoutes
);

const authRoutes = require('./routes/authRoutes');
app.use('/api/auth', authRoutes);

const dashboardRoutes =
  require('./routes/dashboardRoutes');

app.use('/api/dashboard', dashboardRoutes);

const aiRoutes = require('./routes/aiRoutes');
app.use('/api/ai', aiRoutes);

// ---- Per-user (Firebase UID scoped) data -------------------------------
const progressRoutes = require('./routes/progressRoutes');
app.use('/api/progress', progressRoutes);

const activityRoutes = require('./routes/activityRoutes');
app.use('/api/activity', activityRoutes);

const smartGptRoutes = require('./routes/smartGptRoutes');
app.use('/api/smartgpt', smartGptRoutes);

app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Smart Student API Running',
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});