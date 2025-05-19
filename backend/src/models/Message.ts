import mongoose from "mongoose";

const MessageSchema = new mongoose.Schema({
  chatId: String,
  userId: String,
  text: String,
  isUser: Boolean,
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Message", MessageSchema);
