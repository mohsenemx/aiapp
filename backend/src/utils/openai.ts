// src/utils/openai.ts
import OpenAI from "openai";
import { OPENAI_API_KEY } from "../env";
export const openai = new OpenAI({
  apiKey: OPENAI_API_KEY,
  baseURL: 'https://api.avalai.ir/v1'
});
