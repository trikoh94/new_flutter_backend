const fetch = require('node-fetch');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const apiKey = process.env.HUGGING_FACE_API_KEY;
const model = 'gpt2-medium';
const baseUrl = 'https://api-inference.huggingface.co/models';

async function testApiKey() {
  console.log('Testing Hugging Face API key...');
  console.log('API Key:', apiKey ? 'Present' : 'Missing');
  
  try {
    // First, try to get model info
    console.log('Requesting model info...');
    const modelResponse = await fetch(`${baseUrl}/${model}`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${apiKey}`
      }
    });
    
    console.log('Model info response status:', modelResponse.status);
    
    if (!modelResponse.ok) {
      const errorData = await modelResponse.text();
      console.error('Error response:', errorData);
      return;
    }
    
    const modelData = await modelResponse.json();
    console.log('Model info:', modelData);
    
    // Then, try a simple inference
    console.log('Testing inference...');
    const inferenceResponse = await fetch(`${baseUrl}/${model}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: 'Hello, this is a test.',
        parameters: {
          max_length: 50,
          temperature: 0.7,
          top_p: 0.9,
          do_sample: true,
          return_full_text: false
        }
      })
    });
    
    console.log('Inference response status:', inferenceResponse.status);
    
    if (!inferenceResponse.ok) {
      const errorData = await inferenceResponse.text();
      console.error('Error response:', errorData);
      return;
    }
    
    const inferenceData = await inferenceResponse.json();
    console.log('Inference response:', inferenceData);
    
    console.log('API key is valid and working!');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

testApiKey(); 