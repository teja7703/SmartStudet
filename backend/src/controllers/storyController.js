const Story = require('../models/Story');

const createStory = async (req, res) => {
  try {
    const story = await Story.create(req.body);

    res.status(201).json({
      success: true,
      data: story,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
const getStories = async (req, res) => {
    try {
      const {
        search,
        category,
        page = 1,
        limit = 10,
      } = req.query;
  
      const filter = {};
  
      if (search) {
        filter.$or = [
          {
            title: {
              $regex: search,
              $options: 'i',
            },
          },
          {
            description: {
              $regex: search,
              $options: 'i',
            },
          },
        ];
      }
  
      if (category) {
        filter.category = category;
      }
  
      const pageNumber = parseInt(page);
      const limitNumber = parseInt(limit);
  
      const skip = (pageNumber - 1) * limitNumber;
  
      const totalRecords = await Story.countDocuments(filter);
  
      const stories = await Story.find(filter)
        .skip(skip)
        .limit(limitNumber)
        .sort({ createdAt: -1 });
  
      res.status(200).json({
        success: true,
        page: pageNumber,
        limit: limitNumber,
        totalRecords,
        totalPages: Math.ceil(totalRecords / limitNumber),
        count: stories.length,
        data: stories,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  };

const getStoryById = async (req, res) => {
  try {
    const story = await Story.findById(req.params.id);

    if (!story) {
      return res.status(404).json({
        success: false,
        message: 'Story not found',
      });
    }

    res.status(200).json({
      success: true,
      data: story,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteStory = async (req, res) => {
  try {
    const story = await Story.findByIdAndDelete(req.params.id);

    if (!story) {
      return res.status(404).json({
        success: false,
        message: 'Story not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Story deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createStory,
  getStories,
  getStoryById,
  deleteStory,
};