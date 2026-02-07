import express from 'express';
import http from 'http';
import { Server } from 'socket.io';

const app = express();
const server = http.createServer(app);
const io = new Server(server);

app.get('/', (req, res) => {
    res.send('WebSocket Server is running!');
});

io.on('connection', (socket) => {
    console.log('A user connected: ', socket.id);

    socket.on('disconnect', () => {
        console.log('User disconnected: ', socket.id);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});