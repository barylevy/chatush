import SwiftUI
import Factory

struct ChatSettingsView: View {
    @Bindable var conversation: Conversation
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
                Section("Chat Details") {
                    TextField("Title", text: $viewModel.editedTitle)
                        .clearButton(text: $viewModel.editedTitle)
                        .onSubmit {
                            Task {
                                await viewModel.saveTitle(for: conversation)
                            }
                        }
                }
                
                Section("LLM Configuration") {
                    Button {
                        showLLMConfiguration = true
                    } label: {
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
                    
                    Text("Future messages will use the selected provider and model")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
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
            .navigationTitle("Chat Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
            .sheet(isPresented: $showLLMConfiguration) {
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
            .alert("Delete Chat", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteConversation(conversation)
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this chat? This action cannot be undone.")
            }
            .task {
                await viewModel.loadConfiguration(for: conversation)
            }
        }
    }
}
