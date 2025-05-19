import express from "express";
import Chat from "../models/Chat";
import Message from "../models/Message";
import { openai } from "../utils/openai";

const router = express.Router();

// Get all chats for user
router.get("/chats/:userId", async (req, res) => {
  const chats = await Chat.find({ userId: req.params.userId });
  res.json(chats);
});

// Create new chat
router.post("/chats", async (req, res) => {
  const { userId, name } = req.body;
  const chat = await Chat.create({ userId, name });
  res.json(chat);
});

// Rename chat
router.put("/chats/:id", async (req, res) => {
  const { name } = req.body;
  await Chat.findByIdAndUpdate(req.params.id, { name });
  res.sendStatus(200);
});

// Delete chat
router.delete("/chats/:id", async (req, res) => {
  await Chat.findByIdAndDelete(req.params.id);
  await Message.deleteMany({ chatId: req.params.id });
  res.sendStatus(200);
});

// Get messages for a chat
router.get("/messages/:chatId", async (req, res) => {
  const messages = await Message.find({ chatId: req.params.chatId });
  res.json(messages);
});

// Send message
router.post("/messages", async (req, res) => {
  const { userId, chatId, text } = req.body;

  const userMsg = await Message.create({
    userId,
    chatId,
    text,
    isUser: true,
  });

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
