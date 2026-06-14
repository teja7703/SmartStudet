const Career = require('../models/Career');

const createCareer = async (req, res) => {
  try {
    const career = await Career.create(req.body);

    res.status(201).json({
      success: true,
      data: career,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const getCareers = async (req, res) => {
    try {
      const { search, page = 1, limit = 10 } = req.query;
  
      const filter = {};
  
      if (search) {
        filter.careerName = {
          $regex: search,
          $options: 'i',
        };
      }
  
      const pageNumber = parseInt(page);
      const limitNumber = parseInt(limit);
  
      const skip = (pageNumber - 1) * limitNumber;
  
      const totalRecords = await Career.countDocuments(filter);
  
      const careers = await Career.find(filter)
        .skip(skip)
        .limit(limitNumber);
  
      res.status(200).json({
        success: true,
        page: pageNumber,
        limit: limitNumber,
        totalRecords,
        totalPages: Math.ceil(totalRecords / limitNumber),
        count: careers.length,
        data: careers,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  };

const getCareerById = async (req, res) => {
  try {
    const career = await Career.findById(req.params.id);

    if (!career) {
      return res.status(404).json({
        success: false,
        message: 'Career not found',
      });
    }

    res.status(200).json({
      success: true,
      data: career,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const deleteCareer = async (req, res) => {
  try {
    const career = await Career.findByIdAndDelete(req.params.id);

    if (!career) {
      return res.status(404).json({
        success: false,
        message: 'Career not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Career deleted successfully',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createCareer,
  getCareers,
  getCareerById,
  deleteCareer,
};