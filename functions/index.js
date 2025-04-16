/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions");
const cors = require("cors")({origin: true});
const fetch = require("node-fetch");

// HuggingFace API 설정
const HF_CONFIG = {
  baseUrl: 'https://api-inference.huggingface.co/models',
  model: 'mistralai/Mistral-7B-Instruct-v0.1',
  headers: {
    'Authorization': `Bearer ${process.env.HUGGING_FACE_API_KEY}`,
    'Content-Type': 'application/json'
  }
};

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// 아이디어 생성 함수
exports.generateIdea = functions
  .runWith({
    timeoutSeconds: 540, // 9분
    memory: '1GB'
  })
  .https.onRequest((request, response) => {
    cors(request, response, async () => {
      try {
        const { prompt, maxLength = 200 } = request.body;
        
        const hfResponse = await fetch(
          `${HF_CONFIG.baseUrl}/${HF_CONFIG.model}`,
          {
            method: 'POST',
            headers: HF_CONFIG.headers,
            body: JSON.stringify({
              inputs: prompt,
              parameters: {
                max_length: maxLength,
                temperature: 0.7,
                top_p: 0.9,
                do_sample: true,
                return_full_text: false
              }
            })
          }
        );

        if (!hfResponse.ok) {
          throw new Error(`HuggingFace API error: ${hfResponse.statusText}`);
        }

        const data = await hfResponse.json();
        response.json({ success: true, data });
      } catch (error) {
        console.error('Error:', error);
        response.status(500).json({ 
          success: false, 
          error: 'Failed to generate idea',
          details: error.message 
        });
      }
    });
  });

// 아이디어 분석 함수
exports.analyzeIdeas = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '1GB'
  })
  .https.onRequest((request, response) => {
    cors(request, response, async () => {
      try {
        const { ideas, analysisType } = request.body;
        
        const prompt = `Analyze the following ideas and provide insights:
          ${JSON.stringify(ideas)}
          Analysis type: ${analysisType}`;

        const hfResponse = await fetch(
          `${HF_CONFIG.baseUrl}/${HF_CONFIG.model}`,
          {
            method: 'POST',
            headers: HF_CONFIG.headers,
            body: JSON.stringify({
              inputs: prompt,
              parameters: {
                max_length: 500,
                temperature: 0.7,
                top_p: 0.9,
                do_sample: true,
                return_full_text: false
              }
            })
          }
        );

        if (!hfResponse.ok) {
          throw new Error(`HuggingFace API error: ${hfResponse.statusText}`);
        }

        const data = await hfResponse.json();
        response.json({ success: true, data });
      } catch (error) {
        console.error('Error:', error);
        response.status(500).json({ 
          success: false, 
          error: 'Failed to analyze ideas',
          details: error.message 
        });
      }
    });
  });

// 아이디어 분류 함수
exports.categorizeIdea = functions
  .runWith({
    timeoutSeconds: 540,
    memory: '1GB'
  })
  .https.onRequest((request, response) => {
    cors(request, response, async () => {
      try {
        const { idea, categories } = request.body;
        
        const prompt = `Categorize this idea into one of these categories: ${categories.join(', ')}
          Idea: ${idea}`;

        const hfResponse = await fetch(
          `${HF_CONFIG.baseUrl}/${HF_CONFIG.model}`,
          {
            method: 'POST',
            headers: HF_CONFIG.headers,
            body: JSON.stringify({
              inputs: prompt,
              parameters: {
                max_length: 100,
                temperature: 0.3,
                top_p: 0.9,
                do_sample: true,
                return_full_text: false
              }
            })
          }
        );

        if (!hfResponse.ok) {
          throw new Error(`HuggingFace API error: ${hfResponse.statusText}`);
        }

        const data = await hfResponse.json();
        response.json({ success: true, data });
      } catch (error) {
        console.error('Error:', error);
        response.status(500).json({ 
          success: false, 
          error: 'Failed to categorize idea',
          details: error.message 
        });
      }
    });
  });
