# NanoChat iOS

A native iOS app for [NanoChat](https://github.com/nanogpt-community/nanochat)


## Download

[Join the TestFlight Beta](https://testflight.apple.com/join/afmPp2xW)

## Features

### Chat
- Real-time streaming responses
- Multi-model support with provider selection
- Web search integration (Linkup, Tavily, Serper, SearXNG)
- Image and document attachments
- Voice input with audio recording
- Text-to-speech playback
- Markdown rendering with syntax highlighting
- Follow-up question suggestions
- Message starring and search
- Batch message operations

### Organization
- **Conversations** - Chat history with pinning support
- **Projects** - Organize conversations into projects
- **Assistants** - Create and manage custom AI assistants
- **Starred Messages** - Quick access to important messages

### Security
- API key stored in Keychain
- Bearer token authentication
- Local data persistence with SwiftData

## Requirements

- Xcode 17.0+
- iOS 26.0+
- Swift 6.2+

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/nanogpt-community/nanochat-ios
   cd nanochat-ios
   ```

2. **Open in Xcode**
   ```bash
   open NanoChatApp.xcodeproj
   ```

3. **Build and Run**
   - Select a simulator or device
   - Press Cmd+R to build and run

## Configuration

### API Key

1. Go to your NanoChat web app (Public instance at t3.0xgingi.xyz or selfhost it yourself)
2. Navigate to Settings > Developer
3. Generate an API key
4. Enter the key in the iOS app login screen

### Server URL

Default server: `https://t3.0xgingi.xyz`

You can connect to a self-hosted NanoChat server by entering your server URL on the login screen.

## Architecture

The app follows **MVVM architecture** with:

- **Models** - SwiftData models for local persistence
- **ViewModels** - `@Observable` classes managing state
- **Views** - SwiftUI views with Liquid Glass styling
- **Services** - Singleton services for API, audio, storage

### Key Components

| Component | Purpose |
|-----------|---------|
| `NanoChatAPI` | HTTP client for all API calls |
| `AuthenticationManager` | User authentication state |
| `ChatViewModel` | Chat functionality and streaming |
| `ModelManager` | AI model and provider management |
| `AssistantManager` | Assistant CRUD operations |
| `KeychainManager` | Secure credential storage |
| `AudioRecorder` | Voice input recording |
| `AudioPlaybackManager` | TTS audio playback |
