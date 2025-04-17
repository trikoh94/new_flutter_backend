const dotenv = require('dotenv');
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// Load environment variables from .env.production
dotenv.config({ path: '.env.production' });

const apiKey = process.env.HUGGING_FACE_API_KEY;
const model = 'stabilityai/stablelm-2-zephyr-1_6b';  // Using the correct model
const baseUrl = 'https://api-inference.huggingface.co/models';

async function testApiKey() {
  console.log('=== Testing Hugging Face API ===');
  console.log('API Key:', apiKey ? 'Present' : 'Missing');
  console.log('Model:', model);
  
  try {
    // First, try to get model info
    console.log('\nRequesting model info...');
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
    console.log('\nTesting inference...');
    const inferenceResponse = await fetch(`${baseUrl}/${model}`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: 'Translate this to Korean: Hello, how are you?',
        parameters: {
          max_length: 50,
          temperature: 0.7,
          top_p: 0.9,
          do_sample: true
        }
      })
    });
    
    console.log('Inference response status:', inferenceResponse.status);
    
    if (!inferenceResponse.ok) {
      const errorText = await inferenceResponse.text();
      console.error('Error response:', errorText);
      try {
        const errorData = JSON.parse(errorText);
        console.error('Parsed error:', errorData);
      } catch (e) {
        console.error('Could not parse error response as JSON');
      }
      return;
    }
    
    const inferenceData = await inferenceResponse.json();
    console.log('Inference response:', inferenceData);
    
    console.log('\nAPI key is valid and working!');
  } catch (error) {
    console.error('Test failed:', error);
  }
}

async function query(data) {
    const maxRetries = 3;
    const retryDelay = 5000; // 5 seconds
    
    for (let i = 0; i < maxRetries; i++) {
        try {
            const response = await fetch(
                `${baseUrl}/${model}`,
                {
                    headers: { 
                        'Authorization': `Bearer ${apiKey}`,
                        'Content-Type': 'application/json'
                    },
                    method: "POST",
                    body: JSON.stringify(data),
                }
            );
            
            console.log(`Inference response status: ${response.status}`);
            
            if (response.status === 503) {
                console.log(`Attempt ${i + 1}/${maxRetries}: Model is loading. Waiting ${retryDelay/1000} seconds...`);
                await new Promise(resolve => setTimeout(resolve, retryDelay));
                continue;
            }
            
            if (!response.ok) {
                const text = await response.text();
                console.log('Error response:', text);
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            
            const result = await response.json();
            return result;
        } catch (error) {
            console.error(`Attempt ${i + 1}/${maxRetries} failed:`, error);
            if (i === maxRetries - 1) throw error;
            await new Promise(resolve => setTimeout(resolve, retryDelay));
        }
    }
    throw new Error(`Failed after ${maxRetries} attempts`);
}

// Run the test
async function runTest() {
    console.log('=== Testing Hugging Face API ===');
    console.log('API Key:', apiKey ? 'Present' : 'Missing');
    console.log('Model:', model);
    console.log();

    try {
        // Test model info endpoint
        console.log('Requesting model info...');
        const modelInfoResponse = await fetch(
            `${baseUrl}/${model}`,
            {
                headers: { Authorization: `Bearer ${apiKey}` },
                method: "GET"
            }
        );
        console.log('Model info response status:', modelInfoResponse.status);
        const modelInfo = await modelInfoResponse.json();
        console.log('Model info:', modelInfo);
        console.log();

        // Test inference
        console.log('Testing inference...');
        const data = {
            inputs: "<|system|>You are a helpful AI assistant. Provide direct and concise answers.</|system|>\n<|user|>What is the capital of France?</|user|>\n<|assistant|>",
            parameters: {
                max_new_tokens: 50,
                temperature: 0.1,
                top_p: 0.9,
                do_sample: true,
                return_full_text: false,
                stop: ["</|assistant|>", "<|user|>"]
            }
        };

        const result = await query(data);
        console.log('Inference result:', result);
    } catch (error) {
        console.error('Error during test:', error);
    }
}

runTest(); 