import Combine
import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var showingClearAlert = false
    @State private var showChatSettings = false
    @Environment(\.dismiss) private var dismiss

    var existingConversation: Conversation?

    var body: some View {
        NavigationStack {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .alert("Clear Conversation", isPresented: $showingClearAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        Task {
                            await viewModel.clearConversation()
                        }
                    }
                } message: {
                    Text("Are you sure you want to clear all messages?")
                }
                .sheet(isPresented: $showChatSettings, onDismiss: {
                    Task {
                        if let conversation = viewModel.conversation {
                            let exists = await viewModel.conversationExists(conversation)
                            if !exists {
                                dismiss()
                            }
                        }
                    }
                }) {
                    if let conversation = viewModel.conversation {
                        ChatSettingsView(
                            conversation: conversation,
                            onConfigurationChanged: { newConfig in
                                Task {
                                    await viewModel.updateConfiguration(newConfig)
                                }
                            }
                        )
                    }
                }
                .overlay {
                    errorOverlay
                }
                .task {
                    if let conversation = existingConversation {
                        await viewModel.loadConversation(conversation)
                    } else {
                        await viewModel.createNewConversation()
                    }
                }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isSelected: viewModel.selectedMessages.contains(message.id),
                                isSelectionMode: viewModel.isSelectionMode
                            )
                            .onTapGesture {
                                if viewModel.isSelectionMode {
                                    viewModel.toggleMessageSelection(message.id)
                                }
                            }
                            .id(message.id)
                        }

                        // Streaming message
                        if viewModel.isStreaming, !viewModel.streamingMessage.isEmpty {
                            MessageBubble(
                                content: viewModel.streamingMessage,
                                isFromUser: false,
                                timestamp: Date(),
                                isStreaming: true
                            )
                            .id("streaming")
                        }

                        // Invisible bottom anchor for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .dismissKeyboardOnScroll()
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.streamingMessage) { _, _ in
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
                .scrollToBottomOnKeyboard(proxy: proxy, bottomId: "bottom")
            }

            Divider()

            // Input area
            HStack {
                TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                    .clearButton(text: $viewModel.inputText)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .lineLimit(1 ... 5)
                    .disabled(viewModel.isSending)

                Button {
                    Task {
                        await viewModel.sendMessage()
                    }
                } label: {
                    Image(systemName: viewModel.isSending ? "hourglass" : "paperplane.circle")
                        .font(.title)
                        .foregroundStyle(viewModel.isInputValid ? .blue : .gray)
                        .padding(4)
                }
                .disabled(!viewModel.isInputValid || viewModel.isSending)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                if viewModel.conversation != nil {
                    showChatSettings = true
                }
            } label: {
                Text(viewModel.conversation?.title ?? "New Chat")
                    .font(.headline)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    viewModel.toggleSelectionMode()
                } label: {
                    Label(viewModel.isSelectionMode ? "Cancel Selection" : "Select Messages", systemImage: "checkmark.circle")
                }

                if viewModel.isSelectionMode, viewModel.hasSelectedMessages {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteSelectedMessages()
                        }
                    } label: {
                        Label("Delete Selected", systemImage: "trash")
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showingClearAlert = true
                } label: {
                    Label("Clear All Messages", systemImage: "trash.fill")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var errorOverlay: some View {
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
    }
}

struct MessageBubble: View {
    var message: Message?
    var content: String
    var isFromUser: Bool
    var timestamp: Date
    var latencyMs: Int?
    var isSelected: Bool = false
    var isSelectionMode: Bool = false
    var isStreaming: Bool = false

    init(message: Message, isSelected: Bool = false, isSelectionMode: Bool = false) {
        self.message = message
        content = message.content
        isFromUser = message.isFromUser
        timestamp = message.timestamp
        latencyMs = message.latencyMs
        self.isSelected = isSelected
        self.isSelectionMode = isSelectionMode
    }

    init(content: String, isFromUser: Bool, timestamp: Date, latencyMs: Int? = nil, isStreaming: Bool = false) {
        message = nil
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.latencyMs = latencyMs
        self.isStreaming = isStreaming
    }

    var body: some View {
        HStack {
            if isFromUser { Spacer() }

            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(content)
                    .padding(12)
                    .background(isFromUser ? Color.blue : Color(.systemGray5))
                    .foregroundStyle(isFromUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack(spacing: 8) {
                    Text(timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let latencyMs {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        let latencyInTenths = Double(latencyMs) / 1000.0
                        Text(String(format: "%.1fs", latencyInTenths))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if isStreaming {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            .overlay(alignment: isFromUser ? .topLeading : .topTrailing) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .gray)
                        .offset(x: isFromUser ? -8 : 8, y: -8)
                }
            }

            if !isFromUser { Spacer() }
        }
    }
}

#Preview {
    ChatView()
}
