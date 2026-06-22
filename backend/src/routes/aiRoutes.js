const express = require("express");
const { GoogleGenerativeAI } = require("@google/generative-ai");

const router = express.Router();

const genAI = new GoogleGenerativeAI(
  process.env.GEMINI_API_KEY
);

router.post("/ask", async (req, res) => {
  try {
    const { question } = req.body;

    if (!question) {
      return res.status(400).json({
        success: false,
        message: "Question is required",
      });
    }

    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const prompt = `
You are Smart Student AI Tutor.

Rules:
- Answer only educational questions.
- Support Class 8 to Inter 2nd Year students.
- Explain simply.
- Give examples whenever possible.
- Support English and Telugu.
- If question is unrelated to education, politely refuse.

Question:
${question}
`;

    const result = await model.generateContent(prompt);

    res.json({
      success: true,
      answer: result.response.text(),
    });
  } catch (e) {
    console.error(e);

    res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

module.exports = router;