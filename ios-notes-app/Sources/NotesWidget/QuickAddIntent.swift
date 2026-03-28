import AppIntents
import SwiftUI

/// AppIntent invoked when the user taps the widget's Quick Add button.
/// Opens the main app directly to the Quick Capture sheet via URL scheme.
struct QuickAddIntent: AppIntent {

    static var title: LocalizedStringResource = "Quick Add Note"
    static var description = IntentDescription("Opens the Notes app to instantly capture a new note.")
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // The URL handler in NotesAppMain.swift listens for notesapp://capture
        // and presents QuickCaptureView as a sheet.
        return .result()
    }
}
