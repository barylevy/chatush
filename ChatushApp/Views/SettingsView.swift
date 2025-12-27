import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var editingConfig: LLMProviderConfig?
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                storageTypeSection
                configurationsSection
                actionsSection
            }
            .navigationTitle("Settings")
            .dismissKeyboardOnScroll()
            .sheet(item: $editingConfig) { config in
                configurationSheet(for: config)
            }
            .alert("Reset Configurations", isPresented: $showingDeleteAlert) {
                resetAlertButtons
            } message: {
                resetAlertMessage
            }
            .overlay {
                messagesOverlay
            }
            .task {
                await viewModel.loadConfigurations()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var storageTypeSection: some View {
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
    }
    
    @ViewBuilder
    private var configurationsSection: some View {
        Section("LLM Configurations") {
            ForEach(viewModel.configurationsData.configurations) { config in
                configurationRow(for: config)
            }
        }
    }
    
    @ViewBuilder
    private func configurationRow(for config: LLMProviderConfig) -> some View {
        HStack {
            activeIndicator(for: config)
            configurationInfo(for: config)
            Spacer()
            editButton(for: config)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.setActiveConfiguration(config.id)
        }
    }
    
    @ViewBuilder
    private func activeIndicator(for config: LLMProviderConfig) -> some View {
        if config.id == viewModel.configurationsData.activeConfigId {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else {
            Image(systemName: "circle")
                .foregroundStyle(.clear)
        }
    }
    
    @ViewBuilder
    private func configurationInfo(for config: LLMProviderConfig) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(config.name)
                .font(.headline)
            
            Text("\(config.provider) · \(config.model)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func editButton(for config: LLMProviderConfig) -> some View {
        Button {
            editingConfig = config
        } label: {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
                .font(.title3)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var actionsSection: some View {
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
    
    // MARK: - Sheets & Alerts
    
    @ViewBuilder
    private func configurationSheet(for config: LLMProviderConfig) -> some View {
        LLMConfigurationView(config: config) { updatedConfig in
            viewModel.updateConfiguration(updatedConfig)
        }
    }
    
    @ViewBuilder
    private var resetAlertButtons: some View {
        Button("Reset", role: .destructive) {
            Task {
                await viewModel.deleteConfigurations()
            }
        }
        Button("Cancel", role: .cancel) {}
    }
    
    private var resetAlertMessage: some View {
        Text("This will reset all configurations to default. Are you sure?")
    }
    
    // MARK: - Overlays
    
    @ViewBuilder
    private var messagesOverlay: some View {
        if let errorMessage = viewModel.errorMessage {
            messageToast(message: errorMessage, color: .red)
                .task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.errorMessage = nil
                }
        }

        if let successMessage = viewModel.successMessage {
            messageToast(message: successMessage, color: .green)
                .task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    viewModel.successMessage = nil
                }
        }
    }
    
    @ViewBuilder
    private func messageToast(message: String, color: Color) -> some View {
        VStack {
            Spacer()
            Text(message)
                .foregroundStyle(.white)
                .padding()
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    SettingsView()
}
