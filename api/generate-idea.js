import Groq from "groq-sdk";
import dotenv from 'dotenv';

dotenv.config();

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { category, keywords } = req.body;
    
    if (!category || !keywords) {
      return res.status(400).json({ error: 'Category and keywords are required' });
    }

    const prompt = `Generate a unique and innovative business idea based on the following:
    Category: ${category}
    Keywords: ${keywords}
    
    Please provide a detailed response including:
    1. Business Name
    2. Brief Description (2-3 sentences)
    3. Target Market
    4. Key Features/Services
    5. Potential Revenue Streams
    
    Format the response in JSON.`;

    const completion = await groq.chat.completions.create({
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
      model: "llama2-70b-4096",
      temperature: 0.7,
      max_tokens: 1024,
    });

    const response = completion.choices[0]?.message?.content;
    
    res.status(200).json({ response });
  } catch (error) {
    console.error('Error generating idea:', error);
    res.status(500).json({ error: error.message });
  }
} 