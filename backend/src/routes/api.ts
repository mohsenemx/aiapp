import express from "express";
import Chat from "../models/Chat";
import Message from "../models/Message";
import { openai } from "../utils/openai";
// ① Do a *named* import of just the functions:
import { resendOtp, sendOtp, verifyOtp, getStars } from "../controllers/authController";

const router = express.Router();

// ── AUTH ──────────────────────────────────────────────
// Use `router.post` so `sendOtp` / `verifyOtp` are treated as RequestHandlers
router.post("/auth/send-otp", sendOtp);
router.post("/auth/verify-otp", verifyOtp);
router.post("/auth/resend-otp", resendOtp);

router.get("/users/:userId/stars", getStars);
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

// ── MESSAGES ──────────────────────────────────────────
router.get("/messages/:chatId", async (req, res) => {
  const messages = await Message.find({ chatId: req.params.chatId });
  res.json(messages);
});
router.post("/messages", async (req, res) => {
  const { userId, chatId, text } = req.body;
  const userMsg = await Message.create({ userId, chatId, text, isUser: true });
  const aiRes = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: text }],
  });
  const aiMsg = await Message.create({
    userId,
    chatId,
    text: aiRes.choices[0].message?.content || "Error",
    isUser: false,
  });
  res.json([userMsg, aiMsg]);
});

export default router;
