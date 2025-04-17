import Groq from "groq-sdk";
import dotenv from 'dotenv';

dotenv.config();

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY,
});

export default async function handler(req, res) {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Credentials', true);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  // Handle OPTIONS request
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  // Get the specific endpoint from the URL
  const path = req.url || '';
  const endpoint = path.split('/').pop() || '';

  try {
    switch (endpoint) {
      case 'test':
        if (req.method === 'GET') {
          return res.status(200).json({ message: "API is working!" });
        }
        break;

      case 'generate-idea':
        if (req.method === 'POST') {
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
            messages: [{ role: "user", content: prompt }],
            model: "llama2-70b-4096",
            temperature: 0.7,
            max_tokens: 1024,
          });

          return res.status(200).json({ response: completion.choices[0]?.message?.content });
        }
        break;

      case 'analyze-ideas':
        if (req.method === 'POST') {
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
            messages: [{ role: "user", content: prompt }],
            model: "llama2-70b-4096",
            temperature: 0.7,
            max_tokens: 2048,
          });

          return res.status(200).json({ response: completion.choices[0]?.message?.content });
        }
        break;

      default:
        return res.status(404).json({ error: 'Endpoint not found', path, endpoint });
    }

    return res.status(405).json({ error: 'Method not allowed' });
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).json({ error: error.message });
  }
} 