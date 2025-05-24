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
router.use("/uploads", express.static(path.resolve(__dirname, "../uploads")));

// Configure multer to store uploads in uploads/ folder
const upload = multer({ dest: path.resolve(__dirname, "../uploads") });
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
    let user = await User.findById(userId);
    const starsNeeded = 50;

    if (user!.stars < starsNeeded) {
      res.status(400).json({ error: "Not enough stars" });
    }
    await User.findByIdAndUpdate(userId, {
      $inc: { stars: -starsNeeded },
    });
    try {
      const imageUrl = `https://m.bahushbot.ir:3001/api/uploads/${file.filename}`;
      // 1️⃣ Save the user's message with the image path
      const userMsg = await Message.create({
        chatId,
        userId,
        text,
        image: imageUrl,
        isUser: true,
      });
      // 2️⃣ Prepare base64-encoded image for OpenAI
      const imageData = fs.readFileSync(file.path, { encoding: "base64" });
      const base64Image = `data:image/jpeg;base64,${imageData}`;

      // 3️⃣ Call GPT-4 with vision
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

      // 4️⃣ Extract AI response text
      const aiText = result.choices[0]?.message?.content || "No response";

      // 5️⃣ Save AI’s response (no image)
      const aiMsg = await Message.create({
        chatId,
        userId: "AI", // or whatever you use for the assistant
        text: aiText,
        isUser: false,
      });
      // 6️⃣ Return both messages
      res.json({ userMsg, aiMsg });
    } catch (error: any) {
      console.error(error);
      res.status(500).json({ error: "Failed to process image and text" });
    }
  }
);

/**
 * POST /images/generate
 * Body: { prompt: string, size?: string, chatId: string, userId: string }
 * Generates an image, deducts stars, and stores messages in the chat
 * Returns: { userMsg, aiMsg }
 */
router.post(
  "/images/generate",
  async (req: express.Request, res: express.Response): Promise<void> => {
    const { prompt, size = "512x512", chatId, userId } = req.body;

    if (!prompt || typeof prompt !== "string" || !chatId || !userId) {
      res.status(400).json({ error: `prompt, chatId and userId are required` });
      return;
    }

    const starsNeeded = 250;
    const user = await User.findById(userId);
    if (!user) {
      res.status(404).json({ error: "User not found" });
      return;
    }
    if (user.stars < starsNeeded) {
      res.status(400).json({ error: "Not enough stars" });
      return;
    }

    // Deduct stars
    await User.findByIdAndUpdate(userId, { $inc: { stars: -starsNeeded } });

    try {
      // 1️⃣ Save user's prompt as a message
      const userMsg = await Message.create({
        chatId,
        userId,
        text: prompt,
        isUser: true,
      });

      // 2️⃣ Generate image using specific model
      const response = await openai.images.generate({
        model: "stability.sd3-large-v1:0",
        prompt,
        n: 1,
        size,
      });
      const imageUrl = response.data![0]?.url ?? "";
      if (!imageUrl) throw new Error("No image URL returned");

      // 3️⃣ Save AI message with image URL
      const aiMsg = await Message.create({
        chatId,
        userId: "AI",
        text: "", // no text, image only
        image: imageUrl,
        isUser: false,
      });

      // 4️⃣ Return both saved messages
      res.json({ userMsg, aiMsg });
    } catch (error: any) {
      console.error("Error generating image:", error);
      res
        .status(500)
        .json({ error: "Failed to generate image", details: error.message });
    }
  }
);

export default router;
