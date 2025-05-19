// src/controllers/messageController.ts
import { Request, Response } from "express";
import { Message } from "../models/Message";
import { askGPT } from "../services/openaiService";

export const listMessages = async (req: Request, res: Response) => {
  const { userId, chatId } = req.params;
  const msgs = await Message.find({ userId, chatId }).sort("createdAt");
  res.json(msgs);
};

export const postMessage = async (req: Request, res: Response) => {
  const { userId, chatId, content } = req.body;
  // save user msg
  const userMsg = await Message.create({
    userId,
    chatId,
    role: "user",
    content,
  });
  // ask GPT
  const reply = await askGPT(content);
  // save assistant msg
  const aiMsg = await Message.create({
    userId,
    chatId,
    role: "assistant",
    content: reply,
  });
  res.status(201).json([userMsg, aiMsg]);
};
