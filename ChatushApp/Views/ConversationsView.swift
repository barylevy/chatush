import SwiftUI

struct ConversationsView: View {
    @State private var viewModel = HistoryViewModel()
    @State private var selectedConversation: Conversation?
    @State private var showChat = false
    @State private var showNewChat = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.conversations.isEmpty, !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "message.slash",
                        description: Text("Start a new chat to see your conversation history")
                    )
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            Button {
                                selectedConversation = conversation
                                showChat = true
                            } label: {
                                ConversationRow(conversation: conversation)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteConversation(conversation)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                                .onAppear {
                                    if conversation == viewModel.conversations.last {
                                        Task {
                                            await viewModel.loadMoreConversations()
                                        }
                                    }
                                }
                        }

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refreshConversations()
                    }
                }
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .navigationDestination(isPresented: $showChat) {
                if let conversation = selectedConversation {
                    ChatView(existingConversation: conversation)
                }
            }
            .navigationDestination(isPresented: $showNewChat) {
                ChatView(existingConversation: nil)
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding()
                    }
                }
            }
            .task {
                await viewModel.loadInitialConversations()
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(conversation.title)
                    .font(.headline)
                Spacer()
                Text(ConversationDateFormatter.formatDate(conversation.lastMessageDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(conversation.providerName, systemImage: "brain")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(conversation.messages.count) messages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ConversationsView()
}
