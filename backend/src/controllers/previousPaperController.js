const PreviousPaper =
  require('../models/PreviousPaper');

const createPreviousPaper = async (req, res) => {
  try {
    const paper =
      await PreviousPaper.create(req.body);

    res.status(201).json({
      success: true,
      data: paper,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const getPreviousPapers = async (req, res) => {
  try {
    const {
      academicLevel,
      subject,
      year,
    } = req.query;

    const filter = {};

    if (academicLevel)
      filter.academicLevel = academicLevel;

    if (subject)
      filter.subject = subject;

    if (year)
      filter.year = Number(year);

    const papers =
      await PreviousPaper.find(filter)
        .sort({ year: -1 });

    res.status(200).json({
      success: true,
      count: papers.length,
      data: papers,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const getPreviousPaperById = async (req, res) => {
  try {
    const paper =
      await PreviousPaper.findById(req.params.id);

    if (!paper) {
      return res.status(404).json({
        success: false,
        message: 'Paper not found',
      });
    }

    res.status(200).json({
      success: true,
      data: paper,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

const deletePreviousPaper = async (req, res) => {
  try {
    await PreviousPaper.findByIdAndDelete(
      req.params.id
    );

    res.status(200).json({
      success: true,
      message: 'Paper deleted',
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

module.exports = {
  createPreviousPaper,
  getPreviousPapers,
  getPreviousPaperById,
  deletePreviousPaper,
};