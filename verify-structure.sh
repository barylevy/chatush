#!/bin/bash

# Chatush - Quick Build Verification Script
# This script checks that all necessary files are in place

echo "🔍 Chatush Project Structure Verification"
echo "=========================================="
echo ""

PROJECT_ROOT="/Users/bari.levi/Dev_env/Chatush"

# Check SDK files
echo "📦 Checking ChatushSDK files..."
SDK_FILES=(
    "ChatushSDK/Sources/ChatushSDK/ChatushSDK.swift"
    "ChatushSDK/Sources/ChatushSDK/Models/ModelConfiguration.swift"
    "ChatushSDK/Sources/ChatushSDK/Models/ModelResponse.swift"
    "ChatushSDK/Sources/ChatushSDK/Models/ChatMessage.swift"
    "ChatushSDK/Sources/ChatushSDK/Protocols/ModelProviderProtocol.swift"
    "ChatushSDK/Sources/ChatushSDK/Providers/OpenAIModelProvider.swift"
    "ChatushSDK/Sources/ChatushSDK/Providers/MockModelProvider.swift"
    "ChatushSDK/Sources/ChatushSDK/Router/ModelRouter.swift"
    "ChatushSDK/Sources/ChatushSDK/Errors/ModelProviderError.swift"
)

SDK_MISSING=0
for file in "${SDK_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        SDK_MISSING=$((SDK_MISSING + 1))
    fi
done

# Check App files
echo ""
echo "📱 Checking ChatushApp files..."
APP_FILES=(
    "ChatushApp/ChatushApp.swift"
    "ChatushApp/Models/Conversation.swift"
    "ChatushApp/Models/Message.swift"
    "ChatushApp/Models/LLMProviderConfig.swift"
    "ChatushApp/Repositories/ConversationsRepositoryProtocol.swift"
    "ChatushApp/Repositories/ConversationsRepository.swift"
    "ChatushApp/Storage/CredentialsStorageProtocol.swift"
    "ChatushApp/Storage/KeychainCredentialsStorage.swift"
    "ChatushApp/Storage/UserDefaultsCredentialsStorage.swift"
    "ChatushApp/DependencyInjection/AppContainer.swift"
    "ChatushApp/ViewModels/HistoryViewModel.swift"
    "ChatushApp/ViewModels/ChatViewModel.swift"
    "ChatushApp/ViewModels/SettingsViewModel.swift"
    "ChatushApp/Views/MainTabView.swift"
    "ChatushApp/Views/HistoryView.swift"
    "ChatushApp/Views/ChatView.swift"
    "ChatushApp/Views/SettingsView.swift"
    "ChatushApp/Views/AboutView.swift"
)

APP_MISSING=0
for file in "${APP_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        APP_MISSING=$((APP_MISSING + 1))
    fi
done

# Check documentation
echo ""
echo "📚 Checking documentation..."
DOC_FILES=(
    "README.md"
    "SETUP_GUIDE.md"
    "PROJECT_SUMMARY.md"
)

DOC_MISSING=0
for file in "${DOC_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ MISSING: $file"
        DOC_MISSING=$((DOC_MISSING + 1))
    fi
done

# Summary
echo ""
echo "=========================================="
echo "📊 Summary:"
echo "  SDK Files: $((${#SDK_FILES[@]} - SDK_MISSING))/${#SDK_FILES[@]}"
echo "  App Files: $((${#APP_FILES[@]} - APP_MISSING))/${#APP_FILES[@]}"
echo "  Documentation: $((${#DOC_FILES[@]} - DOC_MISSING))/${#DOC_FILES[@]}"

TOTAL_MISSING=$((SDK_MISSING + APP_MISSING + DOC_MISSING))

if [ $TOTAL_MISSING -eq 0 ]; then
    echo ""
    echo "✅ All files are in place!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Open ChatushApp.xcodeproj in Xcode"
    echo "  2. Add Factory package dependency:"
    echo "     - Project Settings → ChatushApp target"
    echo "     - General → Frameworks, Libraries, and Embedded Content"
    echo "     - Click '+' → Add Package Dependency"
    echo "     - URL: https://github.com/hmlongco/Factory.git"
    echo "     - Version: 2.3.0 or later"
    echo "  3. Build & Run (Cmd+R)"
    echo ""
    echo "📖 For detailed instructions, see SETUP_GUIDE.md"
else
    echo ""
    echo "⚠️  $TOTAL_MISSING file(s) missing!"
    echo "Please check the output above for details."
fi

echo ""
