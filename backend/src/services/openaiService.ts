// src/services/openaiService.ts
import OpenAI from "openai";
const openai = new OpenAI();

export async function askGPT(prompt: string) {
  const res = await openai.chat.completions.create({
    model: "gpt-3.5-turbo",
    messages: [{ role: "user", content: prompt }],
  });
  return res.choices[0].message?.content ?? "";
}
