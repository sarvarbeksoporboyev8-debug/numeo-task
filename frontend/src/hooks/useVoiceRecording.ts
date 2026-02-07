import { useState, useEffect } from 'react';

const useVoiceRecording = () => {
    const [recording, setRecording] = useState(false);
    const [audioBlob, setAudioBlob] = useState(null);
    const mediaRecorderRef = useRef(null);

    useEffect(() => {
        const handleSuccess = (stream) => {
            mediaRecorderRef.current = new MediaRecorder(stream);
            mediaRecorderRef.current.ondataavailable = handleDataAvailable;
        };

        navigator.mediaDevices.getUserMedia({ audio: true })
            .then(handleSuccess);
    }, []);

    const handleDataAvailable = (event) => {
        if (event.data.size > 0) {
            setAudioBlob(event.data);
        }
    };

    const startRecording = () => {
        setRecording(true);
        mediaRecorderRef.current.start();
    };

    const stopRecording = () => {
        setRecording(false);
        mediaRecorderRef.current.stop();
    };

    return { recording, startRecording, stopRecording, audioBlob };
};

export default useVoiceRecording;