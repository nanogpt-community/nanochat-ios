# NanoChat iOS App

A native iOS application for [NanoChat](https://github.com/nanogpt-community/nanochat), built with SwiftUI and the Liquid Glass design system.

## Download

[Join the TestFlight Beta](https://testflight.apple.com/join/afmPp2xW)

## Features

- **Liquid Glass UI** - Modern, translucent interface with iOS 26's Liquid Glass design
- **NanoChat Integration** - Real-time chat with [NanoChat](https://github.com/nanogpt-community/nanochat)
- **Multiple Assistants** - Create and manage custom AI assistants
- **Projects** - Organize conversations into projects
- **Secure Authentication** - API key-based authentication
- **SwiftData** - Local data persistence with SwiftData
- **Background Sync** - Automatic synchronization with NanoChat backend

## Requirements

- Xcode 17.0+
- iOS 26.0+
- Swift 6.2+

## Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/nanogpt-community/nanochat-ios
   ```

2. **Open in Xcode**
   ```bash
   open nanochat-ios/NanoChat.xcodeproj
   ```

3. **Build and Run**
   - Select a simulator or device
   - Press Cmd+R to build and run

## Configuration

### Server URL

Default: `https://t3.0xgingi.xyz`

Change in Settings or use:
```swift
APIConfiguration.shared.save(baseURL: "https://your-server.com")
```

### API Key

Generate an API key from the [NanoChat](https://github.com/nanogpt-community/nanochat) web app under Settings > developer.

## Development

### Adding New Features

1. Create model in `Models/`
2. Add API methods in `Services/NanoChatAPI.swift`
3. Create view model in `ViewModels/`
4. Build UI in `Views/`
5. Apply Liquid Glass styling
