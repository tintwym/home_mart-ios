import SwiftUI
import SwiftData

struct MessagesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatThread.createdAt, order: .reverse) private var threads: [ChatThread]

    @State private var searchText: String = ""
    @State private var isShowingEdit = false
    @State private var homeAlert: HomeAlert?

    private var thread: ChatThread? { threads.first }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    if let t = thread {
                        NavigationLink {
                            ChatView(thread: t)
                        } label: {
                            ConversationRow(
                                title: t.title,
                                preview: latestPreview(for: t),
                                timeLabel: latestTimeLabel(for: t),
                                unreadCount: 0,
                                avatarColor: Color(.systemBlue),
                                isOnline: true
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .padding(.leading, 74)
                    } else {
                        emptyState
                            .frame(maxWidth: .infinity)
                            .padding(.top, 120)
                    }
                }
            }

            bottomSearchBar
        }
        .background(Color(.systemBackground))
        .navigationTitle("Messages")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isShowingEdit.toggle() }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6), in: Capsule())
            }
        }
        .alert(item: $homeAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
    }

    private var bottomSearchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemGray6), in: Capsule())

            Button {
                homeAlert = HomeAlert(title: "Audio", message: "Not wired up yet.")
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Audio message")

            Button {
                homeAlert = HomeAlert(title: "New message", message: "Not wired up yet.")
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("New message")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 6)

            Text("No Messages")
                .font(.title3.weight(.semibold))

            Text("Messages you send or receive will appear here.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private struct HomeAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private func latestPreview(for thread: ChatThread) -> String {
        thread.messages.sorted(by: { $0.sentAt > $1.sentAt }).first?.text ?? ""
    }

    private func latestTimeLabel(for thread: ChatThread) -> String {
        guard let d = thread.messages.sorted(by: { $0.sentAt > $1.sentAt }).first?.sentAt else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}

private struct ConversationRow: View {
    let title: String
    let preview: String
    let timeLabel: String
    let unreadCount: Int
    let avatarColor: Color
    let isOnline: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(avatarColor)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(initials(title))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    )

                if isOnline {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        )
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(timeLabel)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(preview)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 8)

                    if unreadCount > 0 {
                        Text(String(unreadCount))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 6)
                            .background(Color(.systemBlue), in: Capsule())
                    }
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? "M"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}
