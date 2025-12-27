import SwiftUI
import Factory

struct ChatSettingsView: View {
    @Bindable var conversation: Conversation
    @State private var viewModel = ChatSettingsViewModel()
    @State private var editedTitle: String = ""
    @State private var showLLMConfiguration = false
    @State private var showDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chat Details") {
                    TextField("Title", text: $editedTitle)
                        .clearButton(text: $editedTitle)
                        .onSubmit {
                            saveTitle()
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
                        saveTitle()
                        dismiss()
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
                editedTitle = conversation.title
                await viewModel.loadConfiguration(for: conversation)
            }
        }
    }
    
    private func saveTitle() {
        if !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            conversation.title = editedTitle
        }
    }
}
