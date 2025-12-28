import Factory
import SwiftUI

struct ChatSettingsView: View {
    var conversation: Conversation
    @State private var viewModel = ChatSettingsViewModel()
    @State private var showLLMConfiguration = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss

    let onConfigurationChanged: ((LLMProviderConfig) -> Void)?

    init(conversation: Conversation, onConfigurationChanged: ((LLMProviderConfig) -> Void)? = nil) {
        self.conversation = conversation
        self.onConfigurationChanged = onConfigurationChanged
    }

    var body: some View {
        NavigationStack {
            Form {
                chatDetailsSection
                llmConfigurationSection
                deleteSection
            }
            .navigationTitle("Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $showLLMConfiguration) {
                llmConfigurationSheet
            }
            .alert("Delete Chat", isPresented: $showDeleteAlert) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
            .task {
                await viewModel.loadConfiguration(for: conversation)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var chatDetailsSection: some View {
        Section("Chat Details") {
            TextField("Title", text: $viewModel.editedTitle)
                .clearButton(text: $viewModel.editedTitle)
                .onSubmit {
                    Task {
                        await viewModel.saveTitle(for: conversation)
                    }
                }
        }
    }

    @ViewBuilder
    private var llmConfigurationSection: some View {
        Section("LLM Configuration") {
            Button {
                showLLMConfiguration = true
            } label: {
                llmConfigurationLabel
            }

            Text("Future messages will use the selected provider and model")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var llmConfigurationLabel: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Provider")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(conversation.providerName)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(conversation.modelName)
                    .font(.body)
                    .foregroundStyle(.primary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
        }
    }

    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Spacer()
                    Text("Delete Chat")
                    Spacer()
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                Task {
                    await viewModel.saveTitle(for: conversation)
                    dismiss()
                }
            }
        }

        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }

    // MARK: - Sheets & Alerts

    @ViewBuilder
    private var llmConfigurationSheet: some View {
        if let config = viewModel.currentConfig {
            LLMConfigurationView(
                config: config,
                onSave: { newConfig in
                    Task {
                        await viewModel.updateConfiguration(newConfig, for: conversation)
                        onConfigurationChanged?(newConfig)
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Cancel", role: .cancel) {}
        Button("Delete", role: .destructive) {
            Task {
                await viewModel.deleteConversation(conversation)
                dismiss()
            }
        }
    }

    private var deleteAlertMessage: some View {
        Text("Are you sure you want to delete this chat? This action cannot be undone.")
    }
}
