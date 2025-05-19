// src/controllers/chatController.ts
import { Request, Response } from "express";
import { Chat } from "../models/Chat";

export const listChats = async (req: Request, res: Response) => {
  const userId = req.params.userId;
  const chats = await Chat.find({ userId }).sort("createdAt");
  res.json(chats);
};

export const createChat = async (req: Request, res: Response) => {
  const { userId, title } = req.body;
  const chat = await Chat.create({ userId, title });
  res.status(201).json(chat);
};

export const deleteChat = async (req: Request, res: Response) => {
  const { chatId } = req.params;
  await Chat.findByIdAndDelete(chatId);
  res.sendStatus(204);
};
