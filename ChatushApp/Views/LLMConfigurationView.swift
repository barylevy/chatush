import SwiftUI

struct LLMConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: LLMConfigurationViewModel
    @State private var showingCancelAlert = false
    
    private let allowProviderChange: Bool

    init(config: LLMProviderConfig, allowProviderChange: Bool = false, onSave: @escaping (LLMProviderConfig) -> Void) {
        _viewModel = State(initialValue: LLMConfigurationViewModel(config: config, onSave: onSave))
        self.allowProviderChange = allowProviderChange
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section("Configuration Name") {
                    TextField("Name", text: $viewModel.config.name)
                        .clearButton(text: $viewModel.config.name)
                        .autocorrectionDisabled()
                }

                // Provider Section
                Section("Provider") {
                    if allowProviderChange {
                        Picker("Provider", selection: $viewModel.config.provider) {
                            Text("OpenAI").tag("openai")
                            Text("Claude").tag("claude")
                            Text("Mock (Local)").tag("mock")
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.config.provider) { _, newProvider in
                            viewModel.config.model = defaultModel(for: newProvider)
                        }
                    } else {
                        HStack {
                            Text("Provider")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(viewModel.config.provider.capitalized)
                        }
                    }

                    TextField("Model", text: $viewModel.config.model)
                        .clearButton(text: $viewModel.config.model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                // API Configuration Section
                if viewModel.config.provider != "mock" {
                    Section("API Configuration") {
                        SecureField("API Key", text: Binding(
                            get: { viewModel.config.apiKey ?? "" },
                            set: { viewModel.config.apiKey = $0.isEmpty ? nil : $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                        TextField("Endpoint (Optional)", text: Binding(
                            get: { viewModel.config.endpoint ?? "" },
                            set: { viewModel.config.endpoint = $0.isEmpty ? nil : $0 }
                        ))
                        .clearButton(text: Binding(
                            get: { viewModel.config.endpoint ?? "" },
                            set: { viewModel.config.endpoint = $0.isEmpty ? nil : $0 }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    }
                }

                // Model Parameters Section
                Section("Model Parameters") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Temperature")
                            Spacer()
                            Text(String(format: "%.2f", viewModel.config.temperature))
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $viewModel.config.temperature, in: 0 ... 2, step: 0.1)
                    }

                    Stepper("Max Tokens: \(viewModel.config.maxTokens)", value: $viewModel.config.maxTokens, in: 100 ... 4000, step: 100)
                }

                // Test Connection Section
                Section {
                    Button {
                        Task {
                            await viewModel.testConnection()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Label("Test Connection", systemImage: "network")
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Edit Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnScroll()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.cancel() {
                            showingCancelAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(viewModel.config.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Unsaved Changes", isPresented: $showingCancelAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        viewModel.errorMessage = nil
                    }
                }

                if let successMessage = viewModel.successMessage {
                    VStack {
                        Spacer()
                        Text(successMessage)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.green)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        viewModel.successMessage = nil
                    }
                }
            }
        }
    }
    
    private func defaultModel(for provider: String) -> String {
        switch provider {
        case "openai":
            return "gpt-4o-mini"
        case "claude":
            return "claude-3-5-sonnet-20241022"
        case "mock":
            return "mock-v1"
        default:
            return ""
        }
    }
}

#Preview {
    LLMConfigurationView(config: .mockConfig) { _ in }
}
