const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables from .env file
dotenv.config();

const app = express();
const port = 3006;

// CORS configuration
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
};

app.use(cors(corsOptions));

// Enable preflight requests for all routes
app.options('*', cors(corsOptions));

app.use(express.json());

// Hugging Face API key
  const apiKey = process.env.HUGGING_FACE_API_KEY;
if (!apiKey) {
  console.error('HUGGING_FACE_API_KEY is not set in environment variables');
  process.exit(1);
}

// Hugging Face API configuration
const HF_CONFIG = {
  model: 'google/flan-t5-base',
  baseUrl: 'https://api-inference.huggingface.co/models',
  headers: {
    'Authorization': `Bearer ${apiKey}`,
    'Content-Type': 'application/json'
  },
  defaultParams: {
    max_length: 500,
    temperature: 0.7,
    top_p: 0.9,
    do_sample: true,
    num_return_sequences: 1,
    repetition_penalty: 1.2
  }
};

// 모델 로딩 상태 확인 함수
async function checkModelStatus() {
  try {
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(
      `${HF_CONFIG.baseUrl}/${HF_CONFIG.model}`,
      {
        method: 'GET',
        headers: HF_CONFIG.headers
      }
    );
    
    if (response.ok) {
      const data = await response.json();
      return { loaded: true, data };
    } else {
      const errorData = await response.json();
      return { loaded: false, error: errorData };
    }
  } catch (error) {
    return { loaded: false, error: error.message };
  }
}

// 모델 로딩을 기다리는 함수
async function waitForModel(maxRetries = 10, delaySeconds = 30) {
  console.log('Waiting for model to load...');
  
  for (let i = 0; i < maxRetries; i++) {
    console.log(`Attempt ${i + 1}/${maxRetries}`);
    
    const status = await checkModelStatus();
    if (status.loaded) {
      console.log('Model is loaded and ready!');
      return true;
    }
    
    if (status.error && status.error.error === 'Model mistralai/Mistral-7B-Instruct-v0.1 is currently loading') {
      console.log(`Model is still loading. Waiting ${delaySeconds} seconds...`);
      await new Promise(resolve => setTimeout(resolve, delaySeconds * 1000));
    } else {
      console.error('Error checking model status:', status.error);
      return false;
    }
  }
  
  console.error('Model failed to load after maximum retries');
  return false;
}

// 서버 시작 시 모델 로딩 시도
waitForModel().then(loaded => {
  if (!loaded) {
    console.error('Failed to load model. The API will attempt to load the model on first request.');
  }
});

// API 요청 래퍼 함수
async function makeHuggingFaceRequest(endpoint, body) {
  const fetch = (await import('node-fetch')).default;
  
  // 최대 3번 재시도
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch(
        `${HF_CONFIG.baseUrl}/${HF_CONFIG.model}`,
        {
      method: 'POST',
          headers: HF_CONFIG.headers,
          body: JSON.stringify(body)
        }
      );
      
      if (response.ok) {
        return await response.json();
      }
      
      const errorData = await response.json();
      
      // 모델이 로딩 중인 경우
      if (errorData.error === 'Model mistralai/Mistral-7B-Instruct-v0.1 is currently loading') {
        console.log(`Model is loading. Attempt ${attempt + 1}/3. Waiting 20 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 20000));
        continue;
      }
      
      throw new Error(JSON.stringify(errorData));
    } catch (error) {
      if (attempt === 2) throw error;
      console.error(`Request failed (attempt ${attempt + 1}/3):`, error);
      await new Promise(resolve => setTimeout(resolve, 5000));
    }
  }
}

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

    const result = await makeHuggingFaceRequest('/analyze-ideas', {
      inputs: prompt,
      parameters: HF_CONFIG.defaultParams
    });
    
    res.json([{ analysis: result[0].generated_text }]);
  } catch (error) {
    console.error('Error analyzing ideas:', error);
    res.status(500).json([{ 
      error: 'Failed to analyze ideas',
      details: error.message
    }]);
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

    const result = await makeHuggingFaceRequest('/categorize-idea', {
      inputs: prompt,
      parameters: HF_CONFIG.defaultParams
    });
    
    res.json([{ 
      category: result[0].generated_text,
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

    const result = await makeHuggingFaceRequest('/check-similarity', {
      inputs: prompt,
      parameters: HF_CONFIG.defaultParams
    });
    
    res.json([{
      similarity_analysis: result[0].generated_text,
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

// 아이디어 생성 엔드포인트
app.post('/api/generate-idea', async (req, res) => {
  try {
    const { prompt } = req.body;
    
    if (!prompt) {
      return res.status(400).json([{ error: 'Prompt is required' }]);
    }

    const enhancedPrompt = `You are an expert app idea generator. Create a detailed and innovative app idea based on this prompt: "${prompt}"

Please provide your response in the following format:
Title: [App Name]
Description: [2-3 sentences about what the app does]
Key Features:
- [Feature 1]
- [Feature 2]
- [Feature 3]
Target Users: [Who would use this app]
Unique Value: [What makes this app different from others]`;

    const result = await makeHuggingFaceRequest('/generate-idea', {
      inputs: enhancedPrompt,
      parameters: HF_CONFIG.defaultParams
    });
    
    res.json([{ generated_text: result[0].generated_text }]);
  } catch (error) {
    console.error('Error generating idea:', error);
    res.status(500).json([{
      error: 'Failed to generate idea',
      details: error.message
    }]);
  }
});

// 테스트용 엔드포인트
app.get('/api/test', async (req, res) => {
  try {
    console.log('=== Testing Hugging Face API ===');
    console.log('API Key:', apiKey ? 'Present' : 'Missing');
    console.log('Model:', HF_CONFIG.model);
    
    const testPrompt = 'Hello, this is a test.';
    console.log('Sending test request to Hugging Face...');
    
    const result = await makeHuggingFaceRequest('/test', {
      inputs: testPrompt,
      parameters: {
        max_length: 50,
        temperature: 0.7,
        top_p: 0.9,
        do_sample: true
      }
    });
    
    console.log('API response:', result);
    
    res.json({
      success: true,
      message: 'API test successful',
      response: result
    });
  } catch (error) {
    console.error('Test failed:', error);
    res.status(500).json({
      error: 'Test failed',
      details: error.message,
      stack: error.stack
    });
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

    const result = await makeHuggingFaceRequest('/summarize-idea', {
      inputs: prompt,
      parameters: {
        ...HF_CONFIG.defaultParams,
        max_length: 400,
        temperature: 0.5
      }
    });
    
    res.json([{ 
      summary: result[0].generated_text,
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

    const result = await makeHuggingFaceRequest('/feedback-idea', {
      inputs: prompt,
      parameters: {
        ...HF_CONFIG.defaultParams,
        max_length: 600,
        temperature: 0.6
      }
    });
    
    res.json([{ 
      feedback: result[0].generated_text,
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
  console.log('Model:', HF_CONFIG.model);
  console.log('CORS enabled for all origins');
  console.log('=== Server Started ===');
});