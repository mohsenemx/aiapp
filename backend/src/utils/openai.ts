// src/utils/openai.ts
import OpenAI from "openai";
import dotenv from "dotenv";
import { resolve } from "path";
dotenv.config({ path: resolve(__dirname, 'env.dev') });

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  baseURL: 'https://api.avalai.ir/v1'
});
