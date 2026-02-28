# NanoChat iOS

Native iOS client for [nanochat](https://github.com/nanogpt-community/nanochat), built with SwiftUI and a Liquid Glass UI.

## Download

- TestFlight: https://testflight.apple.com/join/afmPp2xW

## What This App Supports

### Chat and Generation

- Real-time streaming responses
- Model selection with per-model provider override
- Web search modes: `off`, `standard`, `deep`
- Web search providers:
  - Linkup
  - Tavily
  - Exa
  - Kagi
  - Perplexity
  - Valyu
  - Brave / Brave Pro / Brave Research
- Provider-specific search options:
  - Exa depth (`fast`, `auto`, `neural`, `deep`)
  - Context size (`low`, `medium`, `high`)
  - Kagi source (`web`, `news`, `search`)
  - Valyu search type (`all`, `web`)
- Reasoning effort control (`low`, `medium`, `high`)
- Temporary mode (do not store conversation)
- Image and document attachments
- Voice input (speech-to-text)
- Text-to-speech playback
- Markdown rendering with syntax highlighting
- Follow-up suggestion chips
- Message actions: star, edit, branch, regenerate, batch operations
- Public conversation toggle and share link actions

### Organization and Navigation

- Conversations with pinning, rename, delete, and move-to-project
- Conversation search modes in sidebar:
  - Word Matching
  - Exact Match
  - Fuzzy Search
- In-chat message search with same search modes
- Assistants management
- Projects management
- Starred messages view
- Native Gallery view in sidebar showing all image files
- Stored files gallery in Settings

### Settings and Account

- Account profile/settings editing
- NanoGPT API key (BYOK) management
- Developer API key management
- Prompt templates management
- Scheduled tasks management
- Audio settings
- Analytics view
- Theme selection (System, Light, Dark)

### Security

- API key stored in Keychain
- Bearer token auth for API calls
- Local persistence with SwiftData
- Authenticated image loading for private storage files

## Requirements

- Xcode 17.0+
- iOS 26.0+
- Swift 6.2+

## Setup

1. Clone the repo:

```bash
git clone https://github.com/nanogpt-community/nanochat-ios
cd nanochat-ios
```

2. Open the project:

```bash
open NanoChatApp.xcodeproj
```

3. Run from Xcode on iPhone or iPad simulator/device.

## Connect to NanoChat

### API Key

1. Open your NanoChat web app (public instance: `https://t3.0xgingi.xyz` or your self-hosted instance).
2. Go to account/developer settings.
3. Generate an API key.
4. Enter it in the iOS app authentication screen.

### Server URL

- Default server: `https://t3.0xgingi.xyz`
- You can point the app to any compatible self-hosted NanoChat server from the login/server settings flow.

## Architecture

The app uses MVVM with SwiftUI:

- Models: `NanoChat/Models`
- ViewModels: `NanoChat/ViewModels`
- Views: `NanoChat/Views`
- Services: `NanoChat/Services`

Key services/components:

- `NanoChatAPI` for HTTP/API integration
- `AuthenticationManager` for auth state
- `ChatViewModel` for chat state/streaming
- `ModelManager` for model/provider state
- `AssistantManager` for assistant CRUD
- `KeychainManager` for credential storage
- `AudioRecorder` / `AudioPlaybackManager` for voice features

## Notes

- This repository currently targets iOS (iPhone/iPad).
- API compatibility depends on the NanoChat server version.
