import axios from 'axios';

class TranslationService {
  constructor(apiKey) {
    this.apiKey = apiKey;
  }

  async translate(text, targetLanguage) {
    // Replace with your actual translation service API URL
    const url = 'https://api.example.com/translate';
    try {
      const response = await axios.post(url, {
        text: text,
        targetLanguage: targetLanguage,
        apiKey: this.apiKey
      });
      return response.data.translatedText;
    } catch (error) {
      console.error('Translation error:', error);
      throw new Error('Failed to translate text');
    }
  }
}

// Example usage:
// const translator = new TranslationService('YOUR_API_KEY');
// translator.translate('Hello, world!', 'es').then(console.log);

export default TranslationService;
