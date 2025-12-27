import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var editingConfig: LLMProviderConfig?
    @State private var showingDeleteAlert = false

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

                // Configurations Section
                Section("LLM Configurations") {
                    ForEach(viewModel.configurationsData.configurations) { config in
                        HStack {
                            if config.id == viewModel.configurationsData.activeConfigId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.clear)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(config.name)
                                    .font(.headline)
                                
                                Text("\(config.provider) · \(config.model)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                editingConfig = config
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.setActiveConfiguration(config.id)
                        }
                    }
                }

                // Actions Section
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Reset to Default", systemImage: "arrow.counterclockwise")
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Settings")
            .dismissKeyboardOnScroll()
            .sheet(item: $editingConfig) { config in
                LLMConfigurationView(config: config) { updatedConfig in
                    viewModel.updateConfiguration(updatedConfig)
                }
            }
            .alert("Reset Configurations", isPresented: $showingDeleteAlert) {
                Button("Reset", role: .destructive) {
                    Task {
                        await viewModel.deleteConfigurations()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all configurations to default. Are you sure?")
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
            .task {
                await viewModel.loadConfigurations()
            }
        }
    }
}

#Preview {
    SettingsView()
}
