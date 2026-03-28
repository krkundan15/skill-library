import Foundation
import SwiftData

@Model
public final class Note {
    public var id: UUID
    /// Raw text content (typed or transcribed from voice)
    public var content: String
    /// Relative path to .m4a recording stored in app's Documents directory
    public var audioFileURL: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var category: NoteCategory
    /// One-sentence AI summary, populated asynchronously after save
    public var summary: String?
    /// Whether AI processing has completed
    public var isProcessed: Bool

    @Relationship(deleteRule: .cascade)
    public var actionItems: [ActionItem]

    public init(
        content: String,
        category: NoteCategory,
        audioFileURL: String? = nil
    ) {
        self.id = UUID()
        self.content = content
        self.audioFileURL = audioFileURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.category = category
        self.summary = nil
        self.isProcessed = false
        self.actionItems = []
    }

    /// Convenience snippet for list cards (first 120 characters)
    public var snippet: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 120 else { return trimmed }
        return String(trimmed.prefix(120)) + "…"
    }

    /// True when the note was created today
    public var isToday: Bool {
        Calendar.current.isDateInToday(createdAt)
    }
}
