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
    const { ideas } = req.body;
    
    if (!ideas || !Array.isArray(ideas) || ideas.length === 0) {
      return res.status(400).json({ error: 'Ideas array is required and must not be empty' });
    }

    const prompt = `Analyze the following business ideas and provide insights:
    
    Ideas:
    ${ideas.map((idea, index) => `${index + 1}. ${JSON.stringify(idea)}`).join('\n')}
    
    For each idea, provide:
    1. SWOT Analysis (Strengths, Weaknesses, Opportunities, Threats)
    2. Market Potential (Score 1-10)
    3. Implementation Difficulty (Score 1-10)
    4. Key Success Factors
    5. Potential Challenges
    6. Recommendations for Improvement
    
    Format the response in JSON with an array of analyses.`;

    const completion = await groq.chat.completions.create({
      messages: [
        {
          role: "user",
          content: prompt,
        },
      ],
      model: "llama2-70b-4096",
      temperature: 0.7,
      max_tokens: 2048,
    });

    const response = completion.choices[0]?.message?.content;
    
    res.status(200).json({ response });
  } catch (error) {
    console.error('Error analyzing ideas:', error);
    res.status(500).json({ error: error.message });
  }
} 