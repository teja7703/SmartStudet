const User = require('../models/User');

const isHttpUrl = (v) =>
  typeof v === 'string' &&
  (v.startsWith('http://') || v.startsWith('https://'));

const loginUser = async (req, res) => {
  try {
    const { firebaseUid, email, phone, name, photoUrl } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message: 'firebaseUid is required',
      });
    }

    // Match an existing account by firebaseUid first, then by the
    // identifier that was actually provided (email or phone).
    const orConditions = [{ firebaseUid }];
    if (email) orConditions.push({ email });
    if (phone) orConditions.push({ phone });

    let user = await User.findOne({ $or: orConditions });

    if (!user) {
      const payload = { firebaseUid };
      if (email) payload.email = email;
      if (phone) payload.phone = phone;
      if (name) payload.name = name;
      if (photoUrl) payload.photoUrl = photoUrl;

      user = await User.create(payload);
      console.log(`[AUTH] created user _id=${user._id} uid=${firebaseUid}`);
    } else {
      // Backfill any newly available identifier/profile info.
      let changed = false;
      if (email && !user.email) {
        user.email = email;
        changed = true;
      }
      if (phone && !user.phone) {
        user.phone = phone;
        changed = true;
      }
      // Refresh a provider-managed (http) photo whenever a newer one is sent,
      // so an expired/changed Google avatar gets updated on re-login. Locally
      // uploaded avatars (data: URIs) are only set, never overwritten by a
      // provider value.
      if (photoUrl && photoUrl !== user.photoUrl) {
        const incomingIsHttp = isHttpUrl(photoUrl);
        const storedIsCustom = user.photoUrl && !isHttpUrl(user.photoUrl);
        if (!user.photoUrl || (incomingIsHttp && !storedIsCustom)) {
          user.photoUrl = photoUrl;
          changed = true;
        }
      }
      if (name && (!user.name || user.name === 'Student')) {
        user.name = name;
        changed = true;
      }
      if (changed) await user.save();
      console.log(
        `[AUTH] login user _id=${user._id} uid=${firebaseUid} changed=${changed}`
      );
    }

    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const updateProfile = async (req, res) => {
  try {
    const { firebaseUid, name, photoUrl } = req.body;

    if (!firebaseUid) {
      return res.status(400).json({
        success: false,
        message: 'firebaseUid is required',
      });
    }

    const user = await User.findOne({ firebaseUid });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (typeof name === 'string' && name.trim()) user.name = name.trim();
    if (typeof photoUrl === 'string') user.photoUrl = photoUrl;

    await user.save();
    console.log(`[AUTH] profile updated _id=${user._id} uid=${firebaseUid}`);

    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Returns the freshest copy of the signed-in user (points, streak, photo).
const getMe = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const user = await User.findOne({ firebaseUid });
    if (!user) {
      return res
        .status(404)
        .json({ success: false, message: 'User not found' });
    }
    res.status(200).json({ success: true, data: user });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  loginUser,
  updateProfile,
  getMe,
};
