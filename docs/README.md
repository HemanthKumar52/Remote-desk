# SyncDesk

Cross-platform remote device control application (AnyDesk/TeamViewer alternative) with Flutter frontend, NestJS backend, PostgreSQL database, and WebRTC for peer-to-peer streaming.

## Project Structure

```
C:\Users\venka\Remote\
├── backend/                    # NestJS API
│   ├── src/
│   │   ├── auth/              # JWT authentication
│   │   ├── users/             # User management
│   │   ├── devices/           # Device registration
│   │   ├── sessions/          # Session management
│   │   ├── pairing/           # Pairing codes
│   │   ├── signaling/         # WebRTC signaling (Socket.io)
│   │   ├── prisma/            # Database service
│   │   └── common/            # Shared utilities
│   ├── prisma/
│   │   └── schema.prisma      # Database schema
│   └── package.json
│
├── app/                        # Flutter App
│   └── lib/
│       ├── core/              # App-wide utilities
│       ├── features/
│       │   ├── auth/          # Login/Register
│       │   ├── dashboard/     # Device dashboard
│       │   ├── pairing/       # Device pairing
│       │   ├── remote_session/# Screen mirroring + control
│       │   └── file_transfer/ # File transfer
│       ├── services/          # WebRTC, Socket, API
│       └── main.dart
│
└── docs/                       # Documentation
```

## Quick Start

### Prerequisites

- Node.js 18+
- Flutter 3.16+
- Docker (for PostgreSQL)

### Backend Setup

1. Start PostgreSQL with Docker:
```bash
cd backend
docker-compose up -d
```

2. Install dependencies:
```bash
npm install
```

3. Generate Prisma client and run migrations:
```bash
npm run prisma:generate
npm run prisma:migrate
```

4. Start the development server:
```bash
npm run start:dev
```

The API will be available at `http://localhost:3000/api`

### Flutter App Setup

1. Navigate to app directory:
```bash
cd app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run on your target platform:
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux

# Android
flutter run -d android
```

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login and get JWT tokens
- `POST /api/auth/refresh` - Refresh access token

### Users
- `GET /api/users/me` - Get current user profile

### Devices
- `POST /api/devices/register` - Register a device
- `GET /api/devices` - List user's devices
- `DELETE /api/devices/:id` - Delete a device

### Pairing
- `POST /api/pairing/generate` - Generate 6-digit pairing code
- `POST /api/pairing/connect` - Connect using pairing code

### Sessions
- `POST /api/sessions` - Create a session
- `GET /api/sessions/active` - Get active sessions
- `GET /api/sessions/history` - Get session history
- `GET /api/sessions/:id` - Get session details
- `PATCH /api/sessions/:id` - Update session status
- `DELETE /api/sessions/:id` - End session

## WebSocket Events (Signaling)

Connect to `/signaling` namespace with JWT token.

### Events
- `join-session` - Join a session room
- `leave-session` - Leave a session room
- `offer` - Send WebRTC offer
- `answer` - Send WebRTC answer
- `ice-candidate` - Send ICE candidate
- `input-event` - Send mouse/keyboard input
- `file-transfer-request` - Request file transfer
- `file-transfer-accept` - Accept file transfer
- `file-chunk` - Send file chunk
- `session-ended` - End session

## Features

- **User Authentication**: JWT-based authentication with refresh tokens
- **Device Registration**: Register and manage multiple devices
- **6-Digit Pairing**: Simple pairing code system (5-minute expiry)
- **Screen Streaming**: WebRTC-based screen capture and streaming
- **Remote Control**: Mouse and keyboard input transmission
- **File Transfer**: Basic file transfer via WebSocket

## Technology Stack

### Backend
- NestJS
- PostgreSQL with Prisma ORM
- Socket.io for WebSocket
- JWT for authentication
- bcrypt for password hashing

### Frontend (Flutter)
- Riverpod for state management
- GoRouter for navigation
- flutter_webrtc for WebRTC
- socket_io_client for WebSocket
- dio for HTTP requests
- flutter_secure_storage for token storage

## Development Notes

### Database Schema

The application uses 4 main models:
- **User**: Email/password authentication
- **Device**: Registered devices with platform info
- **Session**: Remote control sessions (host/client)
- **PairCode**: 6-digit pairing codes with expiry

### WebRTC Flow

1. Host generates pairing code
2. Client enters code to connect
3. Backend creates session and notifies both parties
4. Host captures screen and creates WebRTC offer
5. Client receives offer and sends answer
6. ICE candidates exchanged
7. P2P connection established for video stream
8. Input events sent via data channel or Socket.io

## License

MIT
