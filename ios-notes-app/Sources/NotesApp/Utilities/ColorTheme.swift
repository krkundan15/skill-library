import SwiftUI
import NotesShared

extension NoteCategory {
    /// Returns the SwiftUI Color for this category.
    /// Uses the named asset catalog color when available (define "PersonalBlue" / "WorkOrange"
    /// in Assets.xcassets); falls back to the built-in system color otherwise.
    public var color: Color {
        #if canImport(UIKit)
        if UIColor(named: colorName) != nil {
            return Color(colorName, bundle: .main)
        }
        #endif
        return systemColor
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
