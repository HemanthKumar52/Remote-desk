# SyncDesk - Next-Generation Remote Desktop

<p align="center">
  <img src="docs/logo.png" alt="SyncDesk Logo" width="200"/>
</p>

<p align="center">
  <strong>A powerful, cross-platform remote device control application</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#usage">Usage</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#api">API</a>
</p>

---

## Overview

SyncDesk is a modern, feature-rich remote desktop application that goes beyond traditional solutions like AnyDesk and TeamViewer. Built with Flutter for cross-platform support and NestJS for a robust backend, SyncDesk offers enterprise-grade features with a consumer-friendly experience.

## What Makes SyncDesk Unique

| Feature | SyncDesk | AnyDesk | TeamViewer |
|---------|----------|---------|------------|
| Voice Chat During Sessions | ✅ | ❌ | ✅ |
| Privacy Zones (Blur Areas) | ✅ | ❌ | ❌ |
| Clipboard History Sync | ✅ | ❌ | ❌ |
| Session Bookmarks | ✅ | ❌ | ❌ |
| Quick Command Palette | ✅ | ❌ | ❌ |
| Remote App Launcher | ✅ | ❌ | ❌ |
| Screen Annotations/Whiteboard | ✅ | ✅ | ✅ |
| Session Recording | ✅ | ✅ | ✅ |
| Device Groups & Folders | ✅ | ✅ | ✅ |
| Adaptive Quality (AI) | ✅ | ✅ | ✅ |
| Two-Factor Authentication | ✅ | ✅ | ✅ |
| Audit Logs | ✅ | ❌ | ✅ |
| Wake-on-LAN | ✅ | ✅ | ✅ |
| Open Source | ✅ | ❌ | ❌ |

## Features

### Core Features
- **Cross-Platform Support** - Windows, macOS, Linux, Android, iOS
- **WebRTC P2P Streaming** - Low-latency, high-quality screen sharing
- **6-Digit Pairing Code** - Simple, secure device pairing
- **JWT Authentication** - Secure user authentication with refresh tokens
- **Device Registration** - Multi-device management

### Advanced Features

#### 🔐 Security
- **Two-Factor Authentication (TOTP)** - Extra layer of security
- **Unattended Access** - Password-protected permanent access
- **Session Permissions** - Granular control (view-only, input, file transfer)
- **Audit Logs** - Complete activity tracking
- **End-to-End Encryption** - Secure communication

#### 🎙️ Communication
- **Voice Chat** - Real-time audio during sessions
- **Session Chat** - Text messaging with history
- **Typing Indicators** - Know when others are typing

#### 🎨 Collaboration
- **Screen Annotations** - Draw, highlight, arrows, text
- **Whiteboard Mode** - Collaborative drawing
- **Multi-Viewer Mode** - Multiple people can watch
- **Collaborative Cursors** - See where others are pointing

#### 🔒 Privacy
- **Privacy Zones** - Blur sensitive areas on screen
- **Blackout Regions** - Completely hide screen areas
- **Preset Zones** - Quick taskbar/dock hiding

#### 📋 Productivity
- **Clipboard Sync** - Bidirectional clipboard with history
- **Quick Commands** - Ctrl+Alt+Del, shortcuts palette
- **Remote App Launcher** - Launch apps on remote device
- **Session Bookmarks** - Save moments with screenshots

#### 📊 Performance
- **Adaptive Quality** - Auto-adjusts based on connection
- **Quality Presets** - Low, Medium, High, Ultra
- **Connection Stats** - Real-time latency, FPS, bandwidth
- **Bandwidth Test** - Test connection before session

#### 🗂️ Organization
- **Device Groups** - Organize devices in folders
- **Address Book** - Save favorite devices
- **Recent Connections** - Quick access to history
- **Search & Filter** - Find devices quickly

#### 🛠️ System Tools
- **Wake-on-LAN** - Wake sleeping devices
- **Remote Restart/Shutdown** - Control power state
- **Process Manager** - View and kill processes
- **System Info** - View remote system specs
- **Remote Commands** - Execute commands

#### 📹 Recording
- **Session Recording** - Record sessions as video
- **Playback** - Review past sessions
- **Storage Management** - Manage recording space

### Multi-Monitor Support
- **Monitor Selection** - Choose specific monitor
- **All Monitors** - View all screens at once
- **Dynamic Switching** - Change monitors during session

## Installation

### Prerequisites
- Node.js 18+
- Flutter 3.16+
- Docker & Docker Compose
- PostgreSQL 16+ (or use Docker)

### Backend Setup

```bash
# Clone the repository
git clone https://github.com/HemanthKumar52/Remote-desk.git
cd Remote-desk

# Start PostgreSQL with Docker
cd backend
docker-compose up -d

# Install dependencies
npm install

# Generate Prisma client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# Start development server
npm run start:dev
```

### Flutter App Setup

```bash
cd app

# Install dependencies
flutter pub get

# Run on your platform
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
flutter run -d chrome   # Web
flutter run             # Mobile (with device connected)
```

## Usage

### Quick Start

1. **Register/Login** - Create an account or sign in
2. **Register Device** - Your device is automatically registered
3. **Generate Code** - Click "Host Session" to get a 6-digit code
4. **Connect** - Enter the code on another device to connect
5. **Control** - View and control the remote device

### Pairing Methods

#### Temporary (6-Digit Code)
- Valid for 5 minutes
- One-time use
- Ideal for quick support

#### Unattended Access
- Permanent access with password
- No code needed
- Ideal for personal devices

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Alt+Del` | Send to remote |
| `Alt+Tab` | Switch windows |
| `Win+D` | Show desktop |
| `Win+L` | Lock screen |
| `F11` | Toggle fullscreen |
| `Esc` | Exit fullscreen |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                              │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │  Auth   │ │Dashboard│ │ Session │ │Settings │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       └──────────┬┴──────────┬┴───────────┘                 │
│            ┌─────┴─────┐ ┌───┴────┐                         │
│            │  Services │ │ WebRTC │                         │
│            └─────┬─────┘ └───┬────┘                         │
└──────────────────┼───────────┼──────────────────────────────┘
                   │           │
         ┌─────────┴───────────┴─────────┐
         │         REST API / WebSocket   │
         └─────────────────┬─────────────┘
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                    NestJS Backend                            │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │  Auth   │ │ Devices │ │Sessions │ │Signaling│           │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │  2FA    │ │  Chat   │ │Annotate │ │Recording│           │
│  └─────────┘ └─────────┘ └─────────┘ └─────────┘           │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐           │
│  │ Groups  │ │AddrBook │ │SysTools │ │  Stats  │           │
│  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘           │
│       └──────────┬┴──────────┬┴───────────┘                 │
│            ┌─────┴─────┐                                     │
│            │  Prisma   │                                     │
│            └─────┬─────┘                                     │
└──────────────────┼──────────────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │    PostgreSQL     │
         └───────────────────┘
```

## API Reference

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/register` | Register new user |
| POST | `/api/auth/login` | Login |
| POST | `/api/auth/refresh` | Refresh token |

### Two-Factor Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/2fa/status` | Get 2FA status |
| POST | `/api/2fa/setup` | Setup 2FA |
| POST | `/api/2fa/enable` | Enable 2FA |
| POST | `/api/2fa/disable` | Disable 2FA |

### Devices
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/devices/register` | Register device |
| GET | `/api/devices` | List devices |
| DELETE | `/api/devices/:id` | Delete device |

### Device Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/device-groups` | Create group |
| GET | `/api/device-groups` | List groups |
| PATCH | `/api/device-groups/:id` | Update group |
| DELETE | `/api/device-groups/:id` | Delete group |

### Address Book
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/address-book` | Add entry |
| GET | `/api/address-book` | List entries |
| GET | `/api/address-book/favorites` | Get favorites |
| GET | `/api/address-book/recent` | Get recent |

### Pairing
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/pairing/generate` | Generate code |
| POST | `/api/pairing/connect` | Connect with code |

### Sessions
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/sessions/active` | Active sessions |
| GET | `/api/sessions/history` | Session history |
| DELETE | `/api/sessions/:id` | End session |

### Recordings
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/recordings/start` | Start recording |
| POST | `/api/recordings/:id/stop` | Stop recording |
| GET | `/api/recordings` | List recordings |
| GET | `/api/recordings/:id/download` | Download |
| DELETE | `/api/recordings/:id` | Delete |

### System Tools
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/system-tools/wake/:deviceId` | Wake-on-LAN |
| GET | `/api/system-tools/device/:id/info` | System info |
| POST | `/api/system-tools/device/:id/unattended` | Configure unattended |

### Audit Logs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/audit-logs` | Get logs |
| GET | `/api/audit-logs/sessions` | Session logs |
| GET | `/api/audit-logs/security` | Security events |

## WebSocket Events

### Signaling (`/signaling`)
- `join-session` - Join session room
- `leave-session` - Leave session
- `offer` / `answer` - WebRTC signaling
- `ice-candidate` - ICE candidates
- `input-event` - Mouse/keyboard events

### Chat (`/chat`)
- `send-message` - Send message
- `typing` - Typing indicator
- `mark-read` - Mark as read

### Annotations (`/annotations`)
- `create-annotation` - Draw annotation
- `delete-annotation` - Remove
- `clear-annotations` - Clear all

### Stats (`/stats`)
- `report-stats` - Send stats
- `request-quality-adjustment` - Change quality

## Technology Stack

### Backend
- **NestJS** - Node.js framework
- **PostgreSQL** - Database
- **Prisma** - ORM
- **Socket.io** - WebSocket
- **JWT** - Authentication
- **bcrypt** - Password hashing

### Frontend
- **Flutter** - Cross-platform UI
- **Riverpod** - State management
- **GoRouter** - Navigation
- **flutter_webrtc** - WebRTC
- **socket_io_client** - WebSocket

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file.

## Acknowledgments

- [flutter_webrtc](https://pub.dev/packages/flutter_webrtc) for WebRTC support
- [NestJS](https://nestjs.com/) for the backend framework
- [Prisma](https://www.prisma.io/) for database ORM

---

<p align="center">
  Made with ❤️ by the SyncDesk Team
</p>
