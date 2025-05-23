import express from "express";
import Chat from "../models/Chat";
import Message from "../models/Message";
import { openai } from "../utils/openai";
import multer from "multer";
import fs from "fs";
import path from "path";
import {
  resendOtp,
  sendOtp,
  verifyOtp,
  getStars,
  guest,
} from "../controllers/authController";
import { User } from "../models/User";

const router = express.Router();
const upload = multer({ dest: "uploads/" });
// ── AUTH ──────────────────────────────────────────────
// Use `router.post` so `sendOtp` / `verifyOtp` are treated as RequestHandlers
router.post("/auth/send-otp", sendOtp);
router.post("/auth/verify-otp", verifyOtp);
router.post("/auth/resend-otp", resendOtp);
router.get("/users/:userId/stars", getStars);

router.post("/auth/guest", guest);
// ── CHAT CRUD ─────────────────────────────────────────
router.get("/chats/:userId", async (req, res) => {
  const chats = await Chat.find({ userId: req.params.userId });
  res.json(chats);
});
router.post("/chats", async (req, res) => {
  const { userId, name } = req.body;
  const chat = await Chat.create({ userId, name });
  res.json(chat);
});
router.put("/chats/:id", async (req, res) => {
  const { name } = req.body;
  await Chat.findByIdAndUpdate(req.params.id, { name });
  res.sendStatus(200);
});
router.delete("/chats/:id", async (req, res) => {
  await Chat.findByIdAndDelete(req.params.id);
  await Message.deleteMany({ chatId: req.params.id });
  res.sendStatus(200);
});

router.get("/messages/:chatId", async (req, res) => {
  const messages = await Message.find({ chatId: req.params.chatId });
  res.json(messages);
});
router.post("/messages", async (req, res) => {
  const { userId, chatId, text } = req.body;
  let user = await User.findById(userId);
  const starsNeeded = text.trim().split(/\s+/).length * 2;

  if (!user) {
    res.status(404).json({ error: "User not found" });
  }

  if (user!.stars < starsNeeded) {
    res.status(400).json({ error: "Not enough stars" });
  }
  await User.findByIdAndUpdate(userId, {
    $inc: { stars: -starsNeeded },
  });

  const userMsg = await Message.create({ userId, chatId, text, isUser: true });

  // Get full message history for this chat
  const messages = await Message.find({ chatId }).sort({ createdAt: 1 });

  // Convert to OpenAI format
  const formattedMessages = messages.map((m) => ({
    role: m.isUser ? "user" : "assistant",
    content: m.text,
  }));

  // Ask OpenAI
  const aiRes = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: formattedMessages as unknown as any[],
  });

  // Save AI response
  const aiText = aiRes.choices[0].message?.content || "Error";
  const aiMsg = await Message.create({
    userId,
    chatId,
    text: aiText,
    isUser: false,
  });

  res.json([userMsg, aiMsg]);
});

router.post("/vision", upload.single("image"), async (req, res) => {
  const text = req.body.text;
  const imagePath = req.file?.path;

  if (!text || !imagePath) {
    res.status(400).json({ error: "Text and image are required" });
    return;
  }

  try {
    const imageData = fs.readFileSync(imagePath, { encoding: "base64" });
    const base64Image = `data:image/jpeg;base64,${imageData}`;

    const result = await openai.chat.completions.create({
      model: "gpt-4o",
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text },
            {
              type: "image_url",
              image_url: { url: base64Image },
            },
          ],
        },
      ],
      max_tokens: 1000,
    });

    fs.unlinkSync(imagePath); // Delete file after use

    const responseText = result.choices[0]?.message?.content || "No response";
    res.json({ response: responseText });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: "Failed to process image and text" });
  }
});

export default router;
