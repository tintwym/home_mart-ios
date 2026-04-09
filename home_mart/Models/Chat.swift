import Foundation
import SwiftData

@Model
final class ChatThread {
    /// Stable identifier used for cross-model filtering (avoids predicate issues with `persistentModelID`).
    var threadID: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.thread)
    var messages: [ChatMessage]

    init(title: String, createdAt: Date = Date(), messages: [ChatMessage] = []) {
        self.threadID = UUID()
        self.title = title
        self.createdAt = createdAt
        self.messages = messages
    }
}

@Model
final class ChatMessage {
    var id: UUID
    /// Denormalized thread identifier for fast filtering.
    var threadID: UUID
    var text: String
    var sentAt: Date
    var isMe: Bool

    @Relationship
    var thread: ChatThread?

    init(text: String, sentAt: Date = Date(), isMe: Bool, thread: ChatThread? = nil) {
        self.id = UUID()
        self.threadID = thread?.threadID ?? UUID()
        self.text = text
        self.sentAt = sentAt
        self.isMe = isMe
        self.thread = thread
    }
}

