import express from 'express';
import { createServer } from 'http';
import { Server as SocketIOServer } from 'socket.io';
import cors from 'cors';
import dotenv from 'dotenv';
import axios from 'axios';
import path from 'path';
import fs from 'fs';
import FormData from 'form-data';

// Load environment variables from .env.local
const envPath = path.join(__dirname, '../.env.local');
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
  console.log('✅ Loaded .env.local from:', envPath);
} else {
  console.warn('⚠️ .env.local not found at:', envPath);
}

// Debug: Print loaded env vars
console.log('🔍 Environment variables:');
console.log('  DEEPSEEK_API_KEY:', process.env.DEEPSEEK_API_KEY ? '***' + process.env.DEEPSEEK_API_KEY.slice(-10) : 'NOT SET');
console.log('  WHISPER_API_KEY:', process.env.WHISPER_API_KEY ? '***' + process.env.WHISPER_API_KEY.slice(-10) : 'NOT SET');

const app = express();
const httpServer = createServer(app);
const io = new SocketIOServer(httpServer, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Serve static files from frontend build
const frontendPath = path.join(__dirname, '../../frontend/build');
app.use(express.static(frontendPath));

const PORT = process.env.PORT || 3001;

// Helper function to transcribe audio using Whisper
async function transcribeAudio(audioData: string): Promise<string> {
  try {
    console.log('🎤 Transcribing audio with Whisper API...');
    
    if (!process.env.WHISPER_API_KEY) {
      throw new Error('WHISPER_API_KEY not set');
    }

    // Convert base64 to buffer
    const base64Data = audioData.replace(/^data:audio\/wav;base64,/, '');
    const audioBuffer = Buffer.from(base64Data, 'base64');

    // Create FormData
    const form = new FormData();
    form.append('file', audioBuffer, { filename: 'audio.wav', contentType: 'audio/wav' });
    form.append('model', 'whisper-1');

    console.log('📡 Calling Whisper API...');
    const response = await axios.post(
      `${process.env.WHISPER_BASE_URL}/audio/transcriptions`,
      form,
      {
        headers: {
          'Authorization': `Bearer ${process.env.WHISPER_API_KEY}`,
          ...form.getHeaders()
        },
        timeout: 60000
      }
    );

    const transcribedText = response.data.text;
    console.log('✅ Transcribed:', transcribedText);
    return transcribedText;
  } catch (error: any) {
    console.error('❌ Whisper API error:', {
      status: error.response?.status,
      message: error.response?.data?.error?.message || error.message
    });
    throw new Error(error.response?.data?.error?.message || 'Failed to transcribe audio');
  }
}

// Helper function to translate text using DeepSeek
async function translateText(text: string, targetLanguage: string): Promise<string> {
  try {
    console.log(`🌐 Translating to ${targetLanguage}...`);
    
    if (!process.env.DEEPSEEK_API_KEY) {
      throw new Error('DEEPSEEK_API_KEY not set');
    }

    const languageMap: { [key: string]: string } = {
      es: 'Spanish',
      fr: 'French',
      de: 'German',
      zh: 'Chinese',
      ja: 'Japanese',
      ko: 'Korean',
      pt: 'Portuguese',
      ru: 'Russian'
    };

    const targetLangName = languageMap[targetLanguage] || targetLanguage;

    console.log('📡 Calling DeepSeek API...');
    const response = await axios.post(
      `${process.env.DEEPSEEK_BASE_URL}/chat/completions`,
      {
        model: process.env.DEEPSEEK_MODEL || 'deepseek-chat',
        messages: [
          {
            role: 'system',
            content: 'You are a translator. Translate the following text to the target language. Only provide the translation, nothing else.'
          },
          {
            role: 'user',
            content: `Translate this text to ${targetLangName}:\n\n${text}`
          }
        ],
        temperature: 0.3,
        max_tokens: 1000
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.DEEPSEEK_API_KEY}`,
          'Content-Type': 'application/json'
        },
        timeout: 30000
      }
    );

    const translatedText = response.data.choices[0].message.content;
    console.log('✅ Translated:', translatedText);
    return translatedText;
  } catch (error: any) {
    console.error('❌ DeepSeek API error:', {
      status: error.response?.status,
      message: error.response?.data?.error?.message || error.message
    });
    throw new Error(error.response?.data?.error?.message || 'Failed to translate text');
  }
}

// WebSocket connection
io.on('connection', (socket) => {
  console.log('🟢 Client connected:', socket.id);

  socket.on('audio', async (data) => {
    console.log('📨 Received audio from client');
    try {
      // Step 1: Transcribe audio to text using Whisper
      const transcribedText = await transcribeAudio(data.audio);

      // Step 2: Translate to target language using DeepSeek
      const translatedText = await translateText(transcribedText, data.targetLanguage);

      // Step 3: Send results back to client
      socket.emit('translation', {
        original: transcribedText,
        translated: translatedText,
        language: data.targetLanguage
      });

      console.log('✅ Translation complete');
    } catch (error: any) {
      console.error('❌ Error:', error.message);
      socket.emit('error', { 
        message: error.message || 'Translation failed'
      });
    }
  });

  socket.on('disconnect', () => {
    console.log('🔴 Client disconnected:', socket.id);
  });
});

// Serve React app on all other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

httpServer.listen(PORT, () => {
  console.log(`\n✅ Server running on port ${PORT}`);
  console.log(`📡 Socket.IO server ready`);
  console.log(`🌐 Frontend available at http://localhost:${PORT}`);
  console.log(`🔑 API Keys configured:`, {
    deepseek: !!process.env.DEEPSEEK_API_KEY,
    whisper: !!process.env.WHISPER_API_KEY
  });
  console.log('');
});
