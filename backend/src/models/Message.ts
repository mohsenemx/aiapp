import mongoose from "mongoose";

const MessageSchema = new mongoose.Schema({
  chatId: {
    type: String,
    required: true,
  },
  userId: {
    type: String,
    required: true,
  },
  text: {
    type: String,
    required: true,
  },
  isUser: {
    type: Boolean,
    required: true,
  },
  image: {
    type: String,
    required: false,
    default: null, // optional image URL or path
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.model("Message", MessageSchema);
