const Activity = require('../models/Activity');

// Upserts a visited item (material/story) for the current user. Re-visiting an
// item just refreshes its timestamp so it floats to the top of the feed.
const recordActivity = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const { type, refId = '', title = '', subtitle = '' } = req.body || {};

    if (!type) {
      return res
        .status(400)
        .json({ success: false, message: 'type is required' });
    }

    const activity = await Activity.findOneAndUpdate(
      { firebaseUid, type, refId },
      { firebaseUid, type, refId, title, subtitle },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    console.log(
      `[ACTIVITY] saved _id=${activity._id} uid=${firebaseUid} type=${type} refId=${refId}`
    );

    res.status(200).json({ success: true, data: activity });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getActivity = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const activities = await Activity.find({ firebaseUid })
      .sort({ updatedAt: -1 })
      .limit(30)
      .lean();

    res.status(200).json({ success: true, data: activities });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const clearActivity = async (req, res) => {
  try {
    await Activity.deleteMany({ firebaseUid: req.firebaseUid });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = { recordActivity, getActivity, clearActivity };
