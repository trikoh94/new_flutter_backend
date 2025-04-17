const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const app = express();
const port = process.env.PORT || 3006;

// CORS configuration - more permissive
app.use(cors());
app.use(express.json());

// Groq API key
const apiKey = process.env.GROQ_API_KEY;
if (!apiKey) {
  console.error('GROQ_API_KEY is not set in environment variables');
  // Don't exit in production, just log the error
  if (process.env.NODE_ENV !== 'production') {
    process.exit(1);
  }
}

// Groq API configuration
const GROQ_CONFIG = {
  model: 'llama2-70b-4096',
  baseUrl: 'https://api.groq.com/openai/v1/chat/completions',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  },
  defaultParams: {
    temperature: 0.7,
    top_p: 0.9,
    max_tokens: 1000
  }
};

// API 요청 래퍼 함수
async function makeGroqRequest(messages) {
  const fetch = (await import('node-fetch')).default;
  
  try {
    const response = await fetch(GROQ_CONFIG.baseUrl, {
      method: 'POST',
      headers: GROQ_CONFIG.headers,
      body: JSON.stringify({
        model: GROQ_CONFIG.model,
        messages: messages,
        ...GROQ_CONFIG.defaultParams
      })
    });
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(JSON.stringify(errorData));
    }
    
    const data = await response.json();
    return data.choices[0].message.content;
  } catch (error) {
    console.error('Groq API Error:', error);
    throw error;
  }
}

// Test endpoint - simplified for testing
app.get('/api/test', async (req, res) => {
  try {
    res.json({ message: "API is working!" });
  } catch (error) {
    console.error('Error in test endpoint:', error);
    res.status(500).json({ error: error.message });
  }
});

// 아이디어 생성 엔드포인트
app.post('/api/generate-idea', async (req, res) => {
  try {
    const { prompt } = req.body;
    
    if (!prompt) {
      return res.status(400).json({ error: 'Prompt is required' });
    }

    const messages = [
      {
        role: "system",
        content: "You are a creative AI assistant specialized in generating innovative ideas. Your responses should be practical, detailed, and actionable."
      },
      {
        role: "user",
        content: prompt
      }
    ];

    const result = await makeGroqRequest(messages);
    res.json({ generated_text: result });
  } catch (error) {
    console.error('Error generating idea:', error);
    res.status(500).json({ error: error.message });
  }
});

// 아이디어 분석 엔드포인트
app.post('/api/analyze-ideas', async (req, res) => {
  try {
    const { ideas } = req.body;
    
    if (!ideas || !Array.isArray(ideas) || ideas.length < 2) {
      return res.status(400).json([{ error: 'At least 2 ideas are required for analysis' }]);
    }

    const prompt = `Analyze these ideas and identify connections:

${ideas.map((idea, index) => `
Idea ${index + 1}:
Title: ${idea.title}
Description: ${idea.description}
`).join('\n')}

Provide analysis in these sections:
1. Common Themes
2. Potential Synergies
3. Innovation Opportunities
4. Implementation Challenges

Be specific and practical.`;

    const messages = [
      {
        role: "system",
        content: "You are an expert AI analyst specialized in identifying connections and opportunities between different ideas. Your analysis should be thorough, practical, and actionable."
      },
      {
        role: "user",
        content: prompt
      }
    ];

    const result = await makeGroqRequest(messages);
    res.json([{ analysis: result }]);
  } catch (error) {
    console.error('Error analyzing ideas:', error);
    res.status(500).json([{ error: error.message }]);
  }
});

// 아이디어 카테고리 분석 엔드포인트
app.post('/api/categorize-idea', async (req, res) => {
  try {
    const { idea } = req.body;
    
    if (!idea) {
      return res.status(400).json([{ error: 'Idea is required' }]);
    }

    const prompt = `Analyze the category of the following idea: ${idea}

Please provide your response in the following format:
1. Category (select one):
   - Technology/IT (software, hardware, AI, etc.)
   - Art/Design (visual arts, design, music, etc.)
   - Business/Startup (entrepreneurship, marketing, services, etc.)
   - Education/Learning (teaching methods, learning tools, educational content, etc.)
   - Environment/Sustainability (eco-friendly, recycling, energy, etc.)
   - Health/Medical (healthcare, medical services, wellness, etc.)
   - Entertainment (games, media, leisure, etc.)
   - Other

2. Explanation (why this category fits)
3. Portfolio Potential (how this idea could be developed into a portfolio project)
4. Related Categories (2-3 other categories this idea could connect with)`;

    const result = await makeGroqRequest([
      { role: "system", content: "You are a helpful assistant specialized in categorizing ideas." },
      { role: "user", content: prompt }
    ]);
    
    res.json([{ 
      category: result,
      idea: idea
    }]);
  } catch (error) {
    console.error('Error categorizing idea:', error);
    res.status(500).json([{
      error: 'Failed to categorize idea',
      details: error.message
    }]);
  }
});

// 텍스트 유사도 검사 엔드포인트
app.post('/api/check-similarity', async (req, res) => {
  try {
    const { text1, text2 } = req.body;
    
    if (!text1 || !text2) {
      return res.status(400).json([{ error: 'Both text inputs are required' }]);
    }

    const prompt = `Compare these two ideas and determine their similarity:

Idea 1: ${text1}
Idea 2: ${text2}

Please provide the analysis in the following format:
1. Common Themes (Shared concepts or elements)
2. Key Differences (Distinct aspects of each idea)
3. Potential Connections (How these ideas could be related)
4. Innovation Value (The potential value of combining these ideas)
5. Conclusion (A comprehensive evaluation of the relationship between these ideas)`;

    const result = await makeGroqRequest([
      { role: "system", content: "You are a helpful assistant specialized in analyzing text similarities." },
      { role: "user", content: prompt }
    ]);
    
    res.json([{
      similarity_analysis: result,
      text1: text1,
      text2: text2
    }]);
  } catch (error) {
    console.error('Error checking similarity:', error);
    res.status(500).json([{
      error: 'Failed to check similarity',
      details: error.message
    }]);
  }
});

// 아이디어 요약 엔드포인트
app.post('/api/summarize-idea', async (req, res) => {
  try {
    const { idea } = req.body;
    
    if (!idea) {
      return res.status(400).json([{ error: 'Idea is required' }]);
    }

    const prompt = `Summarize and analyze this idea in a structured way:

Title: ${idea.title}
Description: ${idea.description}

Please provide:
1. Core Value Proposition (1-2 sentences)
2. Key Features (bullet points)
3. Target Users (specific demographic)
4. Main Benefits (what problems does it solve?)
5. Implementation Complexity (Low/Medium/High)
6. Market Potential (Low/Medium/High)

Be concise and practical.`;

    const result = await makeGroqRequest([
      { role: "system", content: "You are a helpful assistant specialized in summarizing and analyzing ideas." },
      { role: "user", content: prompt }
    ]);
    
    res.json([{ 
      summary: result,
      idea: idea
    }]);
  } catch (error) {
    console.error('Error summarizing idea:', error);
    res.status(500).json([{
      error: 'Failed to summarize idea',
      details: error.message
    }]);
  }
});

// 아이디어 피드백 엔드포인트
app.post('/api/feedback-idea', async (req, res) => {
  try {
    const { idea } = req.body;
    
    if (!idea) {
      return res.status(400).json([{ error: 'Idea is required' }]);
    }

    const prompt = `Provide detailed feedback on this idea:

Title: ${idea.title}
Description: ${idea.description}

Please analyze:
1. Strengths (what makes this idea unique and valuable?)
2. Weaknesses (what are the potential challenges?)
3. Opportunities (what market gaps could this fill?)
4. Threats (what competitors or obstacles might exist?)
5. Improvement Suggestions (specific recommendations)
6. Next Steps (concrete actions to move forward)

Be constructive and specific.`;

    const result = await makeGroqRequest([
      { role: "system", content: "You are a helpful assistant specialized in providing detailed feedback on ideas." },
      { role: "user", content: prompt }
    ]);
    
    res.json([{ 
      feedback: result,
      idea: idea
    }]);
  } catch (error) {
    console.error('Error providing feedback:', error);
    res.status(500).json([{
      error: 'Failed to provide feedback',
      details: error.message
    }]);
  }
});

// 서버 리스닝
app.listen(port, '0.0.0.0', () => {
  console.log('=== Server Starting ===');
  console.log(`Server is running on http://localhost:${port}`);
  console.log('API Key:', apiKey ? 'Present' : 'Missing');
  console.log('Model:', GROQ_CONFIG.model);
  console.log('CORS enabled for all origins');
  console.log('=== Server Started ===');
});

// For Vercel serverless functions
module.exports = app;