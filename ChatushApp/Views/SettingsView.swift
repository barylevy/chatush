import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                // Storage Type Section
                Section("Storage Type") {
                    Picker("Storage", selection: $viewModel.storageType) {
                        ForEach(StorageType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .onChange(of: viewModel.storageType) { _, newValue in
                        viewModel.changeStorageType(newValue)
                    }

                    Text("Current: \(viewModel.storageType.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Provider Section
                Section("Provider") {
                    Picker("Provider", selection: $viewModel.config.provider) {
                        Text("OpenAI").tag("openai")
                        Text("Mock (Local)").tag("mock")
                    }
                    .pickerStyle(.segmented)

                    TextField("Model", text: $viewModel.config.model)
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

                // Actions Section
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

                    Button {
                        Task {
                            await viewModel.saveConfig()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Configuration", systemImage: "checkmark.circle")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)

                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteConfig()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }

                // Provider Info Section
                Section("Current Configuration") {
                    LabeledContent("Provider", value: viewModel.config.provider)
                    LabeledContent("Model", value: viewModel.config.model)
                    LabeledContent("Temperature", value: String(format: "%.2f", viewModel.config.temperature))
                    LabeledContent("Max Tokens", value: "\(viewModel.config.maxTokens)")
                }
            }
            .navigationTitle("Settings")
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
                }
            }
            .task {
                await viewModel.loadConfig()
            }
        }
    }
}

#Preview {
    SettingsView()
}
