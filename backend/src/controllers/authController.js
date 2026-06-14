const User = require('../models/User');

const loginUser = async (req, res) => {
    try {
      const {
        firebaseUid,
        email,
        name,
        photoUrl,
      } = req.body;
  
      let user = await User.findOne({
        $or: [
          { firebaseUid },
          { email }
        ]
      });
  
      if (!user) {
        user = await User.create({
          firebaseUid,
          email,
          name,
          photoUrl,
        });
      }
  
      res.status(200).json({
        success: true,
        data: user,
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  };

module.exports = {
  loginUser,
};