import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .padding(.top, 40)

                    // App Name
                    Text("Chatush")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("AI Chat Application")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    Divider()
                        .padding(.horizontal)

                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        InfoSection(
                            title: "About Chatush",
                            description: "Chatush is a powerful AI chat application that allows you to interact with multiple Large Language Model (LLM) providers. Switch seamlessly between different AI models and enjoy intelligent conversations."
                        )

                        InfoSection(
                            title: "Features",
                            description: """
                            • Multiple LLM provider support (OpenAI, Mock)
                            • Real-time streaming responses
                            • Conversation history with paging
                            • Secure credential storage (Keychain/UserDefaults)
                            • Switch providers mid-conversation
                            • Message management (delete, clear)
                            • Customizable model parameters
                            """
                        )

                        InfoSection(
                            title: "Architecture",
                            description: "Built with SwiftUI and SwiftData, following MVVM architecture with dependency injection using Factory. The modular SDK design allows easy integration of new LLM providers."
                        )

                        InfoSection(
                            title: "Technology Stack",
                            description: """
                            • SwiftUI for modern UI
                            • SwiftData for local persistence
                            • Factory for dependency injection
                            • Custom ChatushSDK for LLM abstraction
                            • Async/Await for concurrency
                            """
                        )
                    }
                    .padding(.horizontal)

                    Divider()
                        .padding(.horizontal)

                    // Version Info
                    VStack(spacing: 8) {
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("© 2025 Chatush")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("Built with ❤️ using Swift")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("About")
        }
    }
}

struct InfoSection: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AboutView()
}
