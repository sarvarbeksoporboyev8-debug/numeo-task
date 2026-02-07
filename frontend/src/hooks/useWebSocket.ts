import { useEffect, useRef, useState } from 'react';

// Custom hook for managing a WebSocket connection
const useWebSocket = (url) => {
    const [data, setData] = useState(null);
    const [error, setError] = useState(null);
    const [isConnected, setIsConnected] = useState(false);
    const ws = useRef(null);

    useEffect(() => {
        ws.current = new WebSocket(url);

        ws.current.onopen = () => {
            setIsConnected(true);
        };

        ws.current.onmessage = (event) => {
            setData(event.data);
        };

        ws.current.onerror = (event) => {
            setError(event);
        };

        ws.current.onclose = () => {
            setIsConnected(false);
        };

        // Cleanup on component unmount
        return () => {
            ws.current.close();
        };
    }, [url]);

    return { data, error, isConnected };
};

export default useWebSocket;