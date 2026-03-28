import SwiftUI
import SwiftData
import NotesShared

@main
struct NotesAppMain: App {

    let modelContainer: ModelContainer
    @StateObject private var orchestrator = AIOrchestrator()

    init() {
        do {
            modelContainer = try ModelContainer(for: Note.self, ActionItem.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(orchestrator)
                .onOpenURL { url in
                    // Handle notesapp://capture deep link from widget
                    if url.scheme == "notesapp", url.host == "capture" {
                        NotificationCenter.default.post(
                            name: .openQuickCapture,
                            object: nil
                        )
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}

extension Notification.Name {
    static let openQuickCapture = Notification.Name("openQuickCapture")
}
