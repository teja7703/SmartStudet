const SmartGptConversation = require('../models/SmartGptConversation');

// Maps a stored conversation to the shape the Flutter client expects
// (id == clientId so the app round-trips it unchanged).
function toClient(doc) {
  return {
    id: doc.clientId,
    title: doc.title,
    updatedAt: doc.updatedAt,
    messages: (doc.messages || []).map((m) => ({
      id: m.id,
      text: m.text,
      sender: m.sender,
      isError: m.isError === true,
    })),
  };
}

const getConversations = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const docs = await SmartGptConversation.find({ firebaseUid })
      .sort({ updatedAt: -1 })
      .limit(50)
      .lean();

    console.log(`[GPT] history uid=${firebaseUid} count=${docs.length}`);
    res.status(200).json({ success: true, data: docs.map(toClient) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Insert-or-update a conversation by its client id.
const upsertConversation = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const body = req.body || {};
    const clientId = (body.id || body.clientId || '').toString();

    if (!clientId) {
      return res
        .status(400)
        .json({ success: false, message: 'conversation id is required' });
    }

    const doc = await SmartGptConversation.findOneAndUpdate(
      { firebaseUid, clientId },
      {
        firebaseUid,
        clientId,
        title: body.title || 'New chat',
        messages: Array.isArray(body.messages) ? body.messages : [],
      },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    console.log(`[GPT] saved _id=${doc._id} uid=${firebaseUid} clientId=${clientId}`);
    res.status(200).json({ success: true, data: toClient(doc) });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const deleteConversation = async (req, res) => {
  try {
    const firebaseUid = req.firebaseUid;
    const clientId = req.params.id;
    await SmartGptConversation.deleteOne({ firebaseUid, clientId });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const clearConversations = async (req, res) => {
  try {
    await SmartGptConversation.deleteMany({ firebaseUid: req.firebaseUid });
    res.status(200).json({ success: true });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  getConversations,
  upsertConversation,
  deleteConversation,
  clearConversations,
};
