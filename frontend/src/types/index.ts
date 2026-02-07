// Types for voice recordings

type VoiceRecording = {
    id: string;
    filePath: string;
    duration: number; // duration in seconds
    language: string;
    createdAt: Date;
};

// Types for translations

type Translation = {
    id: string;
    text: string;
    language: string;
    translatedText: string;
    createdAt: Date;
};

export type { VoiceRecording, Translation };