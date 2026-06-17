import Foundation
import SwiftData

@Model
public final class Note {
    public var id: UUID
    /// Raw text content (typed note, or short transcript for quick voice notes)
    public var content: String
    /// Relative path to .m4a recording stored in app's Documents directory
    public var audioFileURL: String?
    public var createdAt: Date
    public var updatedAt: Date
    public var category: NoteCategory
    /// One-sentence (quick note) or paragraph (meeting) AI summary
    public var summary: String?
    /// Whether AI processing has completed
    public var isProcessed: Bool
    /// Distinguishes a short quick-captured note from a recorded meeting
    public var noteType: NoteType
    /// Full transcript text for meeting recordings (content holds the title for meetings)
    public var transcript: String?
    /// Bulleted key discussion points extracted from a meeting transcript
    public var keyPoints: [String]
    /// Bulleted decisions extracted from a meeting transcript
    public var decisions: [String]
    /// Recording length in seconds, for meeting notes
    public var duration: TimeInterval?

    @Relationship(deleteRule: .cascade)
    public var actionItems: [ActionItem]

    public init(
        content: String,
        category: NoteCategory,
        audioFileURL: String? = nil,
        noteType: NoteType = .quick,
        transcript: String? = nil,
        duration: TimeInterval? = nil
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
        self.noteType = noteType
        self.transcript = transcript
        self.keyPoints = []
        self.decisions = []
        self.duration = duration
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

    /// "32:08" style formatted duration, for meeting notes
    public var formattedDuration: String? {
        guard let duration else { return nil }
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}
