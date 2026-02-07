import React, { useState, useRef, useEffect } from 'react';
import './App.css';
import { io } from 'socket.io-client';

interface Translation {
  original: string;
  translated: string;
  language: string;
}

const App: React.FC = () => {
  const [isRecording, setIsRecording] = useState(false);
  const [translations, setTranslations] = useState<Translation[]>([]);
  const [targetLanguage, setTargetLanguage] = useState('es');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [connected, setConnected] = useState(false);
  
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);
  const socketRef = useRef<any>(null);

  useEffect(() => {
    // Connect to Socket.IO server
    const socket = io({
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 5000,
      reconnectionAttempts: 5
    });

    socketRef.current = socket;

    socket.on('connect', () => {
      console.log('✅ Connected to server');
      setConnected(true);
      setError(null);
    });

    socket.on('disconnect', () => {
      console.log('❌ Disconnected from server');
      setConnected(false);
    });

    socket.on('translation', (data: Translation) => {
      console.log('📨 Translation received:', data);
      setTranslations([data, ...translations]);
      setIsLoading(false);
    });

    socket.on('error', (data: any) => {
      console.error('❌ Server error:', data);
      setError(data.message || 'Server error');
      setIsLoading(false);
    });

    socket.on('connect_error', (error: any) => {
      console.error('Connection error:', error);
      setError('Failed to connect to server');
    });

    return () => {
      socket.disconnect();
    };
  }, []);

  const startRecording = async () => {
    try {
      setError(null);
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mediaRecorder = new MediaRecorder(stream);
      mediaRecorderRef.current = mediaRecorder;
      audioChunksRef.current = [];

      mediaRecorder.ondataavailable = (event) => {
        audioChunksRef.current.push(event.data);
      };

      mediaRecorder.onstop = () => {
        const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' });
        sendAudioToBackend(audioBlob);
      };

      mediaRecorder.start();
      setIsRecording(true);
      console.log('🔴 Recording started');
    } catch (err) {
      console.error('Microphone error:', err);
      setError('Microphone access denied');
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      mediaRecorderRef.current.stream.getTracks().forEach(track => track.stop());
      setIsRecording(false);
      setIsLoading(true);
      console.log('⏹️ Recording stopped');
    }
  };

  const sendAudioToBackend = (audioBlob: Blob) => {
    if (!connected) {
      setError('Not connected to server. Please refresh.');
      setIsLoading(false);
      return;
    }

    const reader = new FileReader();
    reader.onload = () => {
      const audioData = reader.result as string;
      socketRef.current.emit('audio', {
        audio: audioData,
        targetLanguage,
      });
      console.log('📤 Audio sent to backend');
    };
    reader.readAsDataURL(audioBlob);
  };

  return (
    <div className="App">
      <h1 className="Title">🎤 Voice Translation</h1>
      
      <div className="status">
        {connected ? (
          <span className="connected">✅ Connected</span>
        ) : (
          <span className="disconnected">❌ Disconnected</span>
        )}
      </div>

      {error && <div className="error-message">{error}</div>}

      <div className="controls">
        <div className="language-selector">
          <label>Target Language:</label>
          <select 
            value={targetLanguage} 
            onChange={(e) => setTargetLanguage(e.target.value)}
            disabled={isRecording || isLoading}
          >
            <option value="es">Spanish</option>
            <option value="fr">French</option>
            <option value="de">German</option>
            <option value="zh">Chinese</option>
            <option value="ja">Japanese</option>
            <option value="ko">Korean</option>
          </select>
        </div>

        <div className="button-group">
          {!isRecording ? (
            <button 
              className="Button" 
              onClick={startRecording} 
              disabled={isLoading || !connected}
            >
              🎤 Start Recording
            </button>
          ) : (
            <button 
              className="Button stop-btn" 
              onClick={stopRecording}
            >
              ⏹️ Stop Recording
            </button>
          )}
        </div>

        {isLoading && <div className="loading">⏳ Processing...</div>}
      </div>

      {translations.length > 0 && (
        <div className="Translations">
          <h2>📝 Translations</h2>
          {translations.map((t, i) => (
            <div key={i} className="Translation">
              <p><strong>Original:</strong> {t.original}</p>
              <p><strong>Translated ({t.language}):</strong> {t.translated}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default App;
