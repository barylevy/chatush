# Chatush Project Setup Guide

## Current Status

✅ **ChatushSDK** - Fully implemented with:
- ModelProviderProtocol
- OpenAIModelProvider (with streaming)
- MockModelProvider (with streaming)
- ModelRouter
- Complete models (ModelConfiguration, ModelResponse, ChatMessage)
- Error handling

✅ **App Data Layer** - Implemented with:
- SwiftData models (Conversation, Message)  
- ConversationsRepository with paging
- Credentials storage (Keychain & UserDefaults)
- LLMProviderConfig model

✅ **App ViewModels** - All implemented:
- HistoryViewModel
- ChatViewModel
- SettingsViewModel

✅ **App Views** - All screens created:
- MainTabView (TabBar)
- HistoryView
- ChatView  
- SettingsView
- AboutView

✅ **Dependency Injection** - Factory container configured with all dependencies

## Required Xcode Setup Steps

Since you're using Xcode 15+ with File System Synchronized groups, you need to:

### 1. Add Factory Package to the App Target

1. Open `ChatushApp.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the `ChatushApp` target
4. Go to "General" tab → "Frameworks, Libraries, and Embedded Content"
5. Click the "+" button
6. Click "Add Package Dependency..."
7. Enter: `https://github.com/hmlongco/Factory.git`
8. Version: "2.3.0" or "Up to Next Major Version"
9. Add to Target: ChatushApp
10. Click "Add Package"

### 2. Verify File System Sync

The project uses File System Synchronized groups, so all files in the `ChatushApp/` folder should be automatically included. To verify:

1. In Xcode navigator, expand "ChatushApp" folder
2. You should see all subdirectories:
   - DependencyInjection/
   - Models/
   - Repositories/
   - Storage/
   - ViewModels/
   - Views/
3. If files are missing, right-click on "ChatushApp" → "Add Files to ChatushApp" and select missing folders

### 3. Build Settings

Ensure minimum deployment target:
- iOS: 18.0 or later
- Swift Language Version: Swift 6

### 4. First Build

1. Clean Build Folder: `Cmd+Shift+K`
2. Build: `Cmd+B`
3. Run: `Cmd+R`

## Testing the App

### Test with Mock Provider (No API Key Needed)

1. Launch the app
2. Go to Settings tab
3. Select "Mock (Local)" as provider
4. Tap "Save Configuration"
5. Go to Chat tab
6. Type a message and send
7. You should see an echo response with a random predefined message

### Test with OpenAI

1. Get an API key from https://platform.openai.com/api-keys
2. Go to Settings tab
3. Select "OpenAI" as provider
4. Enter your API key
5. Set model (e.g., "gpt-4o-mini" or "gpt-3.5-turbo")
6. Tap "Test Connection" to verify
7. Tap "Save Configuration"
8. Go to Chat tab
9. Send a message - you should see streaming responses

## Features to Test

### History Tab
- ✅ View all conversations
- ✅ Pagination (scroll to load more)
- ✅ Pull to refresh
- ✅ Swipe to delete conversations
- ✅ Tap to continue conversation

### Chat Tab  
- ✅ Send messages
- ✅ Receive streaming responses
- ✅ See timestamps and latency
- ✅ Select multiple messages (tap menu → Select Messages)
- ✅ Delete selected messages
- ✅ Clear all messages

### Settings Tab
- ✅ Switch storage type (Keychain/UserDefaults)
- ✅ Select provider (OpenAI/Mock)
- ✅ Configure API key
- ✅ Set temperature & max tokens
- ✅ Test connection
- ✅ Save/reset configuration

### About Tab
- ✅ View app information
- ✅ See features and architecture

## Troubleshooting

### "No such module 'Factory'"
- Follow step 1 above to add Factory package to Xcode project
- Clean build folder and rebuild

### "Cannot find 'Conversation' in scope"
- Verify all files are visible in Xcode navigator
- The project uses File System Synchronized groups - files should auto-appear
- Try: Xcode → File → Add Files to "ChatushApp" → Select missing folders

### App crashes on launch
- Check that SwiftData is properly initialized
- Verify iOS deployment target is 18.0+
- Check Console for error messages

### API errors with OpenAI
- Verify API key is correct (starts with "sk-")
- Check you have credits in your OpenAI account
- Verify model name is correct (e.g., "gpt-4o-mini")
- Check internet connection

## File Structure Reference

```
ChatushApp/
├── ChatushApp.swift               # App entry point with SwiftData
├── ContentView.swift              # Legacy view (not used)
├── DependencyInjection/
│   └── AppContainer.swift         # Factory DI container
├── Models/
│   ├── Conversation.swift         # SwiftData model
│   ├── Message.swift              # SwiftData model
│   └── LLMProviderConfig.swift    # Configuration model
├── Repositories/
│   ├── ConversationsRepositoryProtocol.swift
│   └── ConversationsRepository.swift
├── Storage/
│   ├── CredentialsStorageProtocol.swift
│   ├── KeychainCredentialsStorage.swift
│   └── UserDefaultsCredentialsStorage.swift
├── ViewModels/
│   ├── HistoryViewModel.swift
│   ├── ChatViewModel.swift
│   └── SettingsViewModel.swift
└── Views/
    ├── MainTabView.swift          # Root view with 4 tabs
    ├── HistoryView.swift
    ├── ChatView.swift
    ├── SettingsView.swift
    └── AboutView.swift

ChatushSDK/
└── Sources/ChatushSDK/
    ├── ChatushSDK.swift           # Main SDK interface
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
    └── Errors/
        └── ModelProviderError.swift
```

## Next Steps

1. Follow the Xcode setup steps above
2. Build and run the app
3. Test with Mock provider first (no API key needed)
4. Then test with OpenAI if you have an API key
5. Explore all features (history, chat, settings, about)

## Architecture Highlights

- **MVVM**: Clean separation between views and logic
- **Factory DI**: Testable, protocol-based dependencies
- **SwiftData**: Modern persistence with paging
- **Actor-based SDK**: Thread-safe by default
- **Streaming Support**: Real-time AI responses
- **Provider Abstraction**: Easy to add new LLM providers
- **Secure Storage**: Keychain for production credentials

---

For any questions or issues, refer to the comprehensive README.md file.
