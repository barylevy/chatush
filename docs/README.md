# Chatush - AI Chat Application with Pluggable Model SDK

A powerful iOS chat application that enables users to interact with multiple Large Language Model (LLM) providers through a modular SDK architecture.

## 📱 Features

- **Multiple LLM Provider Support**: Switch between OpenAI and Mock (local) providers
- **Real-time Streaming**: Support for streaming responses where available
- **Conversation Management**: Full chat history with pagination support
- **Mid-Conversation Switching**: Change LLM providers without creating a new conversation
- **Secure Credential Storage**: Choose between Keychain or UserDefaults for storing API credentials
- **Message Management**: Delete individual messages or clear entire conversations
- **Customizable Parameters**: Adjust temperature, max tokens, and other model parameters
- **MVVM Architecture**: Clean separation of concerns with dependency injection via Factory
- **SwiftData Persistence**: Modern data persistence with automatic syncing

## 🏗️ Architecture

### Project Structure

```
Chatush/
├── ChatushApp/                 # Main iOS Application
│   ├── Models/                # Data models (LLMProviderConfig)
│   │   ├── Conversation.swift
│   │   ├── Message.swift
│   │   └── LLMProviderConfig.swift
│   ├── ViewModels/            # MVVM ViewModels
│   │   ├── HistoryViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/                 # SwiftUI Views
│   │   ├── MainTabView.swift
│   │   ├── HistoryView.swift
│   │   ├── ChatView.swift
│   │   ├── SettingsView.swift
│   │   └── AboutView.swift
│   ├── Repositories/          # Data repository layer
│   │   ├── ConversationsRepositoryProtocol.swift
│   │   └── ConversationsRepository.swift
│   ├── Storage/               # Credential storage implementations
│   │   ├── CredentialsStorageProtocol.swift
│   │   ├── KeychainCredentialsStorage.swift
│   │   └── UserDefaultsCredentialsStorage.swift
│   └── DependencyInjection/   # Factory DI container
│       └── AppContainer.swift
│
└── ChatushSDK/                # Modular SDK Package
    └── Sources/
        └── ChatushSDK/
            ├── Models/
            │   ├── ModelConfiguration.swift
            │   ├── ModelResponse.swift
            │   └── ChatMessage.swift
            ├── Protocols/
            │   └── ModelProviderProtocol.swift
            ├── Providers/
            │   ├── OpenAIModelProvider.swift
            │   └── MockModelProvider.swift
            ├── Router/
            │   └── ModelRouter.swift
            ├── Errors/
            │   └── ModelProviderError.swift
            └── ChatushSDK.swift
```

### Design Patterns

- **MVVM (Model-View-ViewModel)**: Clean separation between UI and business logic
- **Repository Pattern**: Abstracts data access layer
- **Dependency Injection**: Uses Factory framework for testable, modular code
- **Protocol-Oriented**: Protocols for all major components enabling easy testing
- **Factory Pattern**: ModelRouter determines which provider to use

## 🔧 Setup Instructions

### Prerequisites

- Xcode 15.0+ (for iOS 18.0+ support)
- iOS 18.0+ device or simulator
- OpenAI API key (for OpenAI provider)

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/bari.levi/Dev_env/Chatush
   ```

2. **Open the project in Xcode**
   ```bash
   open ChatushApp.xcodeproj
   ```

3. **Build the project**
   - The ChatushSDK will be automatically built as a local Swift Package
   - Factory dependency will be downloaded automatically

4. **Run the application**
   - Select a simulator or device
   - Press `Cmd+R` to build and run

## 🚀 Usage

### First Time Setup

1. Launch the app
2. Navigate to the **Settings** tab (gear icon)
3. Choose your storage type (Keychain recommended for security)
4. Select a provider:
   - **OpenAI**: Requires API key
   - **Mock**: Works without configuration for testing

### For OpenAI Provider

1. In Settings, select "OpenAI" as the provider
2. Enter your OpenAI API key
3. Set the model (e.g., `gpt-4o-mini`, `gpt-3.5-turbo`)
4. (Optional) Customize temperature and max tokens
5. Tap "Test Connection" to verify
6. Tap "Save Configuration"

### For Mock Provider

1. In Settings, select "Mock" as the provider
2. No API key required
3. Tap "Save Configuration"

### Starting a Chat

1. Navigate to the **Chat** tab (message icon)
2. Type your message in the input field
3. Tap the send button
4. Watch the response appear (with streaming if supported)

### Managing Conversations

- **View History**: Check the **History** tab for all past conversations
- **Continue Chat**: Tap any conversation to continue
- **Delete Conversation**: Swipe left on a conversation
- **Clear Messages**: Use the menu (•••) in chat view
- **Select & Delete**: Use selection mode to delete multiple messages

### Switching Providers Mid-Conversation

1. Go to **Settings**
2. Change the provider or model
3. Save the configuration
4. Return to your chat - new messages will use the new provider

## 🔌 SDK Integration

### Real API: OpenAI

The SDK integrates with OpenAI's Chat Completions API:

**Endpoint**: `https://api.openai.com/v1/chat/completions`

**Supported Features**:
- Standard completion
- Streaming responses
- Multiple models (GPT-4, GPT-3.5-turbo, etc.)
- Temperature and token control

### Mock Provider

The mock provider simulates AI responses:
- Echoes the user's message
- Adds a random predefined response
- Simulates network latency
- Supports streaming simulation

## 📊 SDK Routing Logic

The `ModelRouter` determines which provider to use:

```swift
// Configuration determines the provider
let config = ModelConfiguration(
    provider: "openai",  // or "mock"
    model: "gpt-4o-mini",
    apiKey: "your-api-key",
    endpoint: nil,  // optional, defaults to OpenAI
    temperature: 0.7,
    maxTokens: 2000
)

// Router selects the appropriate provider
let response = try await sdk.sendMessage(messages: messages, config: config)
```

### Provider Selection Flow

1. App reads configuration from storage (Keychain/UserDefaults)
2. Configuration passed to SDK via `ModelConfiguration`
3. `ModelRouter` looks up provider by name
4. Router delegates to appropriate `ModelProvider` implementation
5. Provider formats request for its specific API
6. Response is normalized to common `ModelResponse` format
7. App receives consistent response regardless of provider

## 🧪 Testing

The architecture is designed for testability:

- **Protocols**: All major components are protocol-based
- **Dependency Injection**: Factory enables easy mocking
- **Repository Pattern**: Data layer can be mocked
- **Provider Pattern**: Easy to create test providers

### Future Test Implementation

```swift
// Example: Mock repository for testing
class MockConversationsRepository: ConversationsRepositoryProtocol {
    var mockConversations: [Conversation] = []
    // Implement protocol methods...
}

// Register in tests
Container.shared.conversationsRepository.register {
    MockConversationsRepository()
}
```

## 📦 Dependencies

- **Factory** (2.3.0+): Dependency injection framework
  - Source: https://github.com/hmlongco/Factory
  - Used for: Managing all app dependencies
  
- **ChatushSDK** (Local Package): Custom LLM abstraction SDK
  - Provides: Unified interface for multiple LLM providers

## 🔐 Security

- **Keychain Storage**: Secure storage for API keys (recommended)
- **UserDefaults Option**: Alternative for non-sensitive scenarios
- **No Hardcoded Keys**: All credentials stored securely
- **HTTPS Only**: All network requests use secure connections

## 🎯 Design Decisions

### Why Factory?

- Compile-time safety for dependency injection
- Zero runtime overhead
- Simple, Swift-native API
- Perfect for SwiftUI with `@Injected`

### Why SwiftData?

- Modern, Swift-native persistence
- Automatic change tracking
- Better performance than CoreData
- Seamless SwiftUI integration

### Why Actor for SDK?

- Thread-safe by default
- Perfect for async/await
- Prevents data races
- No manual locking required

### Two Storage Implementations?

- **Keychain**: Production-ready, secure for API keys
- **UserDefaults**: Simpler, useful for testing/development
- **Factory**: Enables runtime switching via settings

## 🌟 Screenshots

### Main Screens

1. **History Tab**: List of all conversations with paging
2. **Chat Tab**: WhatsApp-style chat interface with streaming
3. **Settings Tab**: Configure provider, credentials, and parameters
4. **About Tab**: App information and feature overview

## 🔮 Future Enhancements (Optional)

- [ ] Additional providers (Anthropic Claude, Google Gemini, Mistral)
- [ ] Token usage tracking and display
- [ ] Export conversation history
- [ ] Search within conversations
- [ ] Voice input support
- [ ] Dark mode optimization
- [ ] Widget support
- [ ] iCloud sync
- [ ] Unit and UI tests

## 📝 Configuration Example

### OpenAI Configuration

```json
{
  "provider": "openai",
  "model": "gpt-4o-mini",
  "apiKey": "sk-...",
  "endpoint": "https://api.openai.com/v1/chat/completions",
  "temperature": 0.7,
  "maxTokens": 2000
}
```

### Mock Configuration

```json
{
  "provider": "mock",
  "model": "mock-v1",
  "apiKey": null,
  "endpoint": null,
  "temperature": 0.7,
  "maxTokens": 2000
}
```

## 🐛 Troubleshooting

### "Failed to load configuration"
- Check storage type in Settings
- Try switching between Keychain and UserDefaults

### "API Error (401)"
- Verify your OpenAI API key is correct
- Check if key has proper permissions

### "Network error"
- Check internet connection
- Verify endpoint URL (or leave blank for default)

### Messages not streaming
- Check if provider supports streaming (OpenAI does, Mock does)
- Verify network connection stability

## 📄 License

This project is created as a demonstration of iOS development skills.

## 👤 Author

**Bari Levi**
- Development Environment: Xcode 15, iOS 18
- Architecture: MVVM with Factory DI
- Date: December 2025

---

Built with ❤️ using Swift and SwiftUI
