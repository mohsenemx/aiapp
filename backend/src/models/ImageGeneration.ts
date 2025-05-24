import mongoose from "mongoose";

const ImageGenerationSchema = new mongoose.Schema({
  prompt: {
    type: String,
    required: true,
  },
  negativePrompt: {
    type: String,
    required: false,
    default: "",
  },
  url: {
    type: String,
    required: true, // the local URL where the image is served
  },
  userId: {
    type: String,
    required: true, // UUID of the user who requested it
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.model("ImageGeneration", ImageGenerationSchema);
