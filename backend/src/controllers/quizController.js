const Quiz = require('../models/Quiz');

const createQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.create(req.body);

    res.status(201).json({
      success: true,
      data: quiz,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const getQuizzes = async (req, res) => {
    try {
      const {
        classLevel,
        category,
        difficulty,
        page = 1,
        limit = 10,
      } = req.query;
  
      const filter = {};
  
      if (classLevel) {
        filter.classLevel = classLevel;
      }
  
      if (category) {
        filter.category = category;
      }
  
      if (difficulty) {
        filter.difficulty = difficulty;
      }
  
      const pageNumber = parseInt(page);
      const limitNumber = parseInt(limit);
  
      const skip = (pageNumber - 1) * limitNumber;
  
      const totalRecords = await Quiz.countDocuments(filter);
  
      const quizzes = await Quiz.find(filter)
        .skip(skip)
        .limit(limitNumber);
  
      res.status(200).json({
        success: true,
        page: pageNumber,
        limit: limitNumber,
        totalRecords,
        totalPages: Math.ceil(totalRecords / limitNumber),
        count: quizzes.length,
        data: quizzes,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  };

const getQuizById = async (req, res) => {
  try {
    const quiz = await Quiz.findById(req.params.id);

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found',
      });
    }

    res.status(200).json({
      success: true,
      data: quiz,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteQuiz = async (req, res) => {
  try {
    const quiz = await Quiz.findByIdAndDelete(req.params.id);

    if (!quiz) {
      return res.status(404).json({
        success: false,
        message: 'Quiz not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Quiz deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createQuiz,
  getQuizzes,
  getQuizById,
  deleteQuiz,
};