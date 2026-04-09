import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.modelContext) private var modelContext

    let thread: ChatThread
    @Query private var messages: [ChatMessage]

    @State private var draft: String = ""
    @State private var scrollAnchor = UUID()
    @FocusState private var isComposerFocused: Bool

    init(thread: ChatThread) {
        self.thread = thread
        let id = thread.threadID
        _messages = Query(
            filter: #Predicate<ChatMessage> { $0.threadID == id },
            sort: [SortDescriptor(\ChatMessage.sentAt, order: .forward)]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesView
            composerBar
        }
        .navigationTitle(thread.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground))
        .onChange(of: messages.count) { _, _ in scrollToBottom() }
        .task { scrollToBottom() }
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { msg in
                        IMessageRow(message: msg)
                            .id(msg.id)
                    }

                    Color.clear
                        .frame(height: 1)
                        .id(scrollAnchor)
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                scrollToBottom(proxy: proxy, animated: false)
            }
            .onChange(of: scrollAnchor) { _, _ in
                scrollToBottom(proxy: proxy, animated: true)
            }
        }
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.25)

            HStack(alignment: .bottom, spacing: 10) {
                Button { } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color(.systemBlue))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Apps")

                TextField("iMessage", text: $draft, axis: .vertical)
                    .focused($isComposerFocused)
                    .lineLimit(1...4)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                Button {
                    sendMessage()
                } label: {
                    Image(systemName: sendButtonSystemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color(.systemBlue), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(sendButtonSystemImage == "mic.fill" ? "Audio" : "Send")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
    }

    private var sendButtonSystemImage: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up"
    }

    private func sendMessage() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let msg = ChatMessage(text: trimmed, sentAt: Date(), isMe: true, thread: thread)
        msg.threadID = thread.threadID
        modelContext.insert(msg)
        try? modelContext.save()
        draft = ""
        scrollToBottom()
    }

    private func scrollToBottom() {
        scrollAnchor = UUID()
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(scrollAnchor, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(scrollAnchor, anchor: .bottom)
        }
    }
}

private struct IMessageRow: View {
    let message: ChatMessage

    private var isMe: Bool { message.isMe }

    var body: some View {
        HStack {
            if isMe { Spacer(minLength: 30) }

            Text(message.text)
                .font(.body)
                .foregroundStyle(isMe ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isMe ? Color(.systemBlue) : Color(.systemGray5))
                )
                .frame(maxWidth: 280, alignment: isMe ? .trailing : .leading)

            if !isMe { Spacer(minLength: 30) }
        }
        .frame(maxWidth: .infinity, alignment: isMe ? .trailing : .leading)
    }
}
