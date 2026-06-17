import Foundation

public enum NoteType: String, Codable, Sendable {
    case quick
    case meeting

    public var displayName: String {
        switch self {
        case .quick: return "Note"
        case .meeting: return "Meeting"
        }
    }

    public var icon: String {
        switch self {
        case .quick: return "note.text"
        case .meeting: return "person.2.wave.2.fill"
        }
    }
}
