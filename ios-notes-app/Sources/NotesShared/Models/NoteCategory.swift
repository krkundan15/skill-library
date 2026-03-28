import SwiftUI

public enum NoteCategory: String, Codable, CaseIterable, Sendable {
    case personal
    case work

    public var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .work: return "Work"
        }
    }

    public var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        }
    }

    /// Asset catalog color name — define "PersonalBlue" and "WorkOrange" in Assets.xcassets
    public var colorName: String {
        switch self {
        case .personal: return "PersonalBlue"
        case .work: return "WorkOrange"
        }
    }

    /// Fallback system color used when asset catalog color is unavailable
    public var systemColor: Color {
        switch self {
        case .personal: return .blue
        case .work: return .orange
        }
    }
}
