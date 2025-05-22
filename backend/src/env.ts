import { resolve } from "path";
import dotenv from "dotenv";

dotenv.config({ path: resolve(__dirname, "env.dev") });

export const PORT = process.env.PORT || 3000;
export const MONGO_URI =
  process.env.MONGO_URI || "mongodb://localhost:27017/aiapp";
export const OPENAI_API_KEY = process.env.OPENAI_API_KEY!;
export const SSL_CERT = process.env.SSL_CERTFILE!;
export const SSL_PRIVKEY = process.env.SSL_PRIVKEY!;
export const API_IR_API_KEY = process.env.API_IR_API_KEY!;
