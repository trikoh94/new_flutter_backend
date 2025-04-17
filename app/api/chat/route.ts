import { Groq } from "groq-sdk";
import { StreamingTextResponse } from 'ai';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export async function POST(req: Request) {
  const { messages } = await req.json();
  const lastMessage = messages[messages.length - 1];
  
  const completion = await groq.chat.completions.create({
    messages: [
      {
        role: "system",
        content: "You are a helpful AI assistant that generates and analyzes business ideas."
      },
      ...messages
    ],
    model: "llama2-70b-4096",
    temperature: 0.7,
    max_tokens: 1024,
    stream: true,
  });

  return new StreamingTextResponse(completion.stream());
} 