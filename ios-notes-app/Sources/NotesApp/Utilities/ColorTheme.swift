import SwiftUI
import NotesShared

extension NoteCategory {
    /// Returns the SwiftUI Color for this category, preferring the asset catalog color.
    public var color: Color {
        // Color(colorName) works if the color is defined in Assets.xcassets;
        // falls back to the system color if not found.
        Color(colorName, bundle: .main)
    }
}

enum AppColor {
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let accent = Color.accentColor
    static let completedAction = Color(.systemGreen)
    static let pendingAction = Color(.systemOrange)
}
