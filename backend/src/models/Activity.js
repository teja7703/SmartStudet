const mongoose = require('mongoose');

// A visited item (study material / story) for a single Firebase user, used to
// build the "Recent Activity" feed and the materials/stories-viewed counts.
const activitySchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
    },
    // 'material' | 'story'
    type: {
      type: String,
      required: true,
    },
    // The content document id this activity refers to.
    refId: {
      type: String,
      default: '',
    },
    title: {
      type: String,
      default: '',
    },
    subtitle: {
      type: String,
      default: '',
    },
  },
  { timestamps: true }
);

// One activity row per (user, type, item) — re-visiting just updates the time.
activitySchema.index(
  { firebaseUid: 1, type: 1, refId: 1 },
  { unique: true }
);

module.exports = mongoose.model('Activity', activitySchema);
