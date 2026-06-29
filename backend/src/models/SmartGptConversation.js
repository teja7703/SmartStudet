const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    id: String,
    text: String,
    // 'user' | 'ai'
    sender: String,
    isError: { type: Boolean, default: false },
  },
  { _id: false }
);

// A saved SmartGPT chat session, scoped to a single Firebase user.
const conversationSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
    },
    // The client-generated conversation id (stable across saves).
    clientId: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      default: 'New chat',
    },
    messages: [messageSchema],
  },
  { timestamps: true }
);

conversationSchema.index(
  { firebaseUid: 1, clientId: 1 },
  { unique: true }
);

module.exports = mongoose.model('SmartGptConversation', conversationSchema);
