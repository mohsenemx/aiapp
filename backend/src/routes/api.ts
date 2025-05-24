import express from "express";
import Chat from "../models/Chat";
import Message from "../models/Message";
import { openai } from "../utils/openai";
import ImageGeneration from "../models/ImageGeneration";
import multer from "multer";
import axios from "axios";
import { v4 as uuidv4 } from "uuid";
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
router.use("/uploads", express.static(path.resolve(__dirname, "../uploads")));

// Multer config
const upload = multer({ dest: path.resolve(__dirname, "../uploads") });

// ── AUTH ──────────────────────────────────────────────
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

// ── MESSAGES ─────────────────────────────────────────
router.get("/messages/:chatId", async (req, res) => {
  const messages = await Message.find({ chatId: req.params.chatId });
  res.json(messages);
});

router.post("/messages", async (req, res) => {
  const { userId, chatId, text } = req.body;
  const user = await User.findOne({ uuid: userId });
  const starsNeeded = text.trim().split(/\s+/).length * 2;

  if (!user) {
    res.status(404).json({ error: "User not found" });
    return;
  }

  if (user.stars < starsNeeded) {
    res.status(400).json({ error: "Not enough stars" });
    return;
  }

  await User.findOneAndUpdate(
    { uuid: userId },
    { $inc: { stars: -starsNeeded } }
  );

  const userMsg = await Message.create({ userId, chatId, text, isUser: true });

  const messages = await Message.find({ chatId }).sort({ createdAt: 1 });
  const formatted = messages.map((m) => ({
    role: m.isUser ? "user" : "assistant",
    content: m.text,
  }));

  const aiRes = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: formatted as unknown as any[],
  });

  const aiText = aiRes.choices[0].message?.content || "Error";
  const aiMsg = await Message.create({
    userId: "AI",
    chatId,
    text: aiText,
    isUser: false,
  });

  res.json([userMsg, aiMsg]);
});

// ── VISION CHAT ────────────────────────────────────────
router.post(
  "/vision",
  upload.single("image"),
  async (req, res): Promise<void> => {
    const { text, chatId, userId } = req.body;
    const file = req.file;

    if (!text || !file || !chatId || !userId) {
      res
        .status(400)
        .json({ error: "text, chatId, userId, and image are required" });
      return;
    }

    const user = await User.findOne({ uuid: userId });
    const starsNeeded = 100;
    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }

    if (user.stars < starsNeeded) {
      res.status(400).json({ error: "Not enough stars" });
      return;
    }

    await User.findOneAndUpdate(
      { uuid: userId },
      { $inc: { stars: -starsNeeded } }
    );

    try {
      const imageUrl = `https://m.bahushbot.ir:3001/api/uploads/${file.filename}`;
      const userMsg = await Message.create({
        chatId,
        userId,
        text,
        image: imageUrl,
        isUser: true,
      });

      const imageData = fs.readFileSync(file.path, { encoding: "base64" });
      const base64Image = `data:${file.mimetype};base64,${imageData}`;

      const result = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              { type: "text", text },
              { type: "image_url", image_url: { url: base64Image } },
            ],
          },
        ],
        max_tokens: 1000,
      });

      const aiText = result.choices[0]?.message?.content || "No response";
      const aiMsg = await Message.create({
        userId: "AI",
        chatId,
        text: aiText,
        isUser: false,
      });

      res.json({ userMsg, aiMsg });
    } catch (err: any) {
      console.error(err);
      res.status(500).json({ error: "Failed to process image and text" });
    }
  }
);

// ── IMAGE GENERATION ───────────────────────────────────
router.post("/images/generate", async (req, res): Promise<void> => {
  const { prompt, size = "1024x1024", chatId, userId } = req.body;

  if (!prompt || !chatId || !userId) {
    res.status(400).json({ error: "prompt, chatId and userId are required" });
    return;
  }

  const starsNeeded = 300;
  const user = await User.findOne({ uuid: userId });
  if (!user) {
    res.status(404).json({ error: "User not found" });
    return;
  }
  if (user.stars < starsNeeded) {
    res.status(400).json({ error: "Not enough stars" });
    return;
  }

  await User.findOneAndUpdate(
    { uuid: userId },
    { $inc: { stars: -starsNeeded } }
  );

  try {
    const userMsg = await Message.create({
      chatId,
      userId,
      text: prompt,
      isUser: true,
    });

    const response = await openai.images.generate({
      model: "dall-e-3",
      prompt,
      n: 1,
      size,
    });
    const externalUrl = response.data![0]?.url;
    if (!externalUrl) throw new Error("No image URL returned");

    // download it
    const imageResp = await axios.get<ArrayBuffer>(externalUrl, {
      responseType: "arraybuffer",
    });
    // choose a unique filename
    const ext = (externalUrl.split(".").pop() || "png").split("?")[0];
    const filename = `${uuidv4()}.${ext}`;
    const filepath = path.resolve(__dirname, "../uploads", filename);
    fs.writeFileSync(filepath, Buffer.from(imageResp.data));

    // build your local URL and store it
    const localUrl = `https://m.bahushbot.ir:3001/api/uploads/${filename}`;
    const aiMsg = await Message.create({
      chatId,
      userId: "AI",
      image: localUrl,
      isUser: false,
    });

    // store in ImageGeneration collection
    await ImageGeneration.create({
      prompt,
      url: localUrl,
      userId,
      createdAt: new Date(),
    });

    res.json({ userMsg, aiMsg });
  } catch (err: any) {
    console.error("Error generating image:", err);
    res
      .status(500)
      .json({ error: "Failed to generate image", details: err.message });
  }
});

export default router;
