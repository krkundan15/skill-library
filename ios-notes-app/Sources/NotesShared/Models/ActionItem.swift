import Foundation
import SwiftData

@Model
public final class ActionItem {
    public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var dueDate: Date?
    public var createdAt: Date
    /// Back-reference to the note this was extracted from
    @Relationship public var note: Note?

    public init(title: String, dueDate: Date? = nil, note: Note? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.dueDate = dueDate
        self.createdAt = Date()
        self.note = note
    }

    /// Grouping bucket for the Actions list
    public var bucket: ActionBucket {
        if isCompleted { return .done }
        guard let due = dueDate else { return .upcoming }
        return Calendar.current.isDateInToday(due) ? .today : .upcoming
    }
}

public enum ActionBucket: String, CaseIterable {
    case today = "Today"
    case upcoming = "Upcoming"
    case done = "Done"
}
