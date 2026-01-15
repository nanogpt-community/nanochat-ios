# CLAUDE.md

Always use Context7 MCP when I need library/API documentation, code generation, setup or configuration steps without me having to explicitly ask.

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

NanoChat iOS is a native iOS app for the [NanoChat](https://github.com/nanogpt-community/nanochat) platform. The parent `nanochat` directory contains the web app/API server (SvelteKit), while this `nanochat-ios` directory contains the native iOS app (SwiftUI).

## Build & Run

**Building the project:**
```bash
xcodebuild -project NanoChatApp.xcodeproj -scheme NanoChatApp -configuration Debug build
```

**Running on simulator:**
```bash
xcodebuild -project NanoChatApp.xcodeproj -scheme NanoChatApp -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Or use Xcode directly:**
```bash
open NanoChatApp.xcodeproj
# Then press Cmd+R in Xcode
```

**IMPORTANT:** The user handles all builds themselves. Do not run xcodebuild commands. The user will provide any build errors or warnings.

## Requirements

- **Xcode:** 17.0+
- **Deployment Target:** iOS 26.0+
- **Swift:** 6.2+ (primary), with some targets using Swift 5.0
- **Bundle ID:** `com.0xgingi.nanochat`

## Architecture

### MVVM Pattern

The app follows a clean **MVVM architecture**:

- **Models** (`NanoChat/Models/`): SwiftData models with relationships for persistence
- **Views** (`NanoChat/Views/`): SwiftUI views with Liquid Glass styling
- **ViewModels** (`NanoChat/ViewModels/`): `@Observable` / `ObservableObject` classes managing state
- **Services** (`NanoChat/Services/`): Singleton services for API, storage, audio, etc.

### Data Flow

```
View (@StateObject) → ViewModel (@Published) → Service → API → SwiftData
```

### Key Architecture Patterns

1. **Singleton Services** - Most services are singletons accessed via `shared` instances
2. **Async/Await** - All API calls use modern Swift concurrency
3. **SwiftData** - Local persistence with cascade delete relationships
4. **MainActor** - UI-related ViewModels run on main actor
5. **Reactive UI** - SwiftUI with `@Published`, `@State`, `@ObservedObject`

## Core Data Models (SwiftData)

Located in `NanoChat/Models/`:

- `Conversation` - Chat sessions with metadata (cost, pinned, project associations)
- `Message` - Individual messages with rich content (images, documents)
- `MessageImage` / `MessageDocument` - Attachments with cascade deletion
- `Project` - Project organization system
- `Assistant` - AI assistant configurations
- `UserSettings` - User preferences

**Important:** Models use SwiftData relationships. Understand cascade delete rules when modifying.

## API Layer

**Service:** `NanoChat/Services/NanoChatAPI.swift` (singleton)

**Configuration:** `NanoChat/Services/APIConfiguration.swift` - manages base URL and API key

**Default Server:** `https://t3.0xgingi.xyz`

**Authentication:** Bearer token via `Authorization` header. API keys stored in Keychain via `KeychainManager`.

### Key API Endpoints

- `GET /conversations` - List conversations
- `POST /conversations` - Create conversation
- `GET /conversations/{id}/messages` - Get messages
- `POST /generate` - Generate message (supports streaming)
- `GET /assistants` - List assistants
- `GET /models` - List available models
- `GET /projects` - List projects
- `POST /tts` - Text-to-speech
- `POST /storage` - File upload

**Full API docs:** `/Volumes/SSD/nanochat/nanochat/api-docs.md`

## Key Services & Managers

Located in `NanoChat/Services/` and `NanoChat/ViewModels/`:

| Service/Manager | Purpose |
|----------------|---------|
| `AuthenticationManager` | User authentication state, login/logout |
| `ThemeManager` | App theme, color schemes, appearance |
| `ChatViewModel` | Core chat functionality, message generation, streaming |
| `ModelManager` | AI model and provider management |
| `AssistantManager` | AI assistant CRUD operations |
| `KeychainManager` | Secure credential storage |
| `AudioRecorder` | Voice input recording |
| `AudioPlaybackManager` | TTS audio playback |
| `NanoChatAPI` | HTTP client for all API calls |

## UI Design System: Liquid Glass

**Location:** `NanoChat/Views/Components/` (reusable components)

**Design Philosophy:** Neon pink/purple palette on pure black with ultra-thin material backgrounds, gradient borders, blur effects, and smooth animations.

**Key Components:**
- `GlassCard` / `LiquidGlassCard` - Glass morphism containers
- `LiquidGlassButtonStyle` - Interactive glass buttons
- `LiquidGlassTextFieldStyle` - Glass effect inputs
- `LiquidGlassModifiers` - View modifiers for glass effects

**Theme File:** `NanoChat/Theme.swift`

**Pattern:** When adding new views, wrap content in `LiquidGlassCard` and apply glass modifiers for consistency.

## Navigation Structure

**Main Entry:** `NanoChat/NanoChatApp.swift`

**Root View:** `MainTabView` with 5 tabs:
1. Chats (`ConversationsListView`)
2. Starred (`StarredMessagesView`)
3. Assistants (`AssistantsListView`)
4. Projects (`ProjectsListView`)
5. Settings (`SettingsView`)

**Authentication:** `AuthenticationView` is shown first if no API key is stored.

## File Organization

```
NanoChat/
├── Models/              # SwiftData models
├── ViewModels/          # Observable view models
├── Views/
│   ├── Components/      # Reusable UI components
│   └── [FeatureViews]/  # Feature-specific views
├── Services/            # API, storage, audio, etc.
├── Theme.swift          # Design tokens
└── NanoChatApp.swift    # App entry point
```

## Common Patterns

### Adding a New Feature

1. Create SwiftData model in `Models/` (if needed)
2. Add API methods in `Services/NanoChatAPI.swift`
3. Create view model in `ViewModels/` (marked `@MainActor` if UI-related)
4. Build UI in `Views/` with Liquid Glass styling
5. Wire up in appropriate tab or navigation

### API Call Pattern

```swift
// All API methods are async/throwing
do {
    let result = try await NanoChatAPI.shared.someMethod()
    // Handle success
} catch {
    // Handle APIError
}
```

### State Management Pattern

```swift
@MainActor
class SomeViewModel: ObservableObject {
    @Published var someProperty: Type = defaultValue

    func someAction() async {
        // Update state
        someProperty = newValue
    }
}
```

## Important Notes

- **Do not build the iOS app** - The user will build and provide errors/warnings
- **Check API docs** before implementing endpoints - see `/Volumes/SSD/nanochat/nanochat/api-docs.md`
- **Use SwiftData relationships** - Don't break existing model relationships
- **Apply Liquid Glass styling** - Maintain visual consistency
- **Store secrets in Keychain** - Never use UserDefaults for sensitive data
- **All API calls are async** - Use proper concurrency patterns
