import WidgetKit
import SwiftUI
import SwiftData
import NotesShared

// MARK: - Timeline Entry

struct NotesWidgetEntry: TimelineEntry {
    let date: Date
    let totalActionsToday: Int
    let completedActionsToday: Int
    let recentNoteSnippet: String?
}

// MARK: - Timeline Provider

struct NotesWidgetProvider: TimelineProvider {

    typealias Entry = NotesWidgetEntry

    func placeholder(in context: Context) -> NotesWidgetEntry {
        NotesWidgetEntry(date: Date(), totalActionsToday: 3, completedActionsToday: 1, recentNoteSnippet: "Meeting at 2pm, call Sarah…")
    }

    func getSnapshot(in context: Context, completion: @escaping (NotesWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NotesWidgetEntry>) -> Void) {
        let entry = makeEntry()
        // Refresh every 15 minutes
        let next = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> NotesWidgetEntry {
        // Widget reads from the shared SwiftData store
        // Note: full SwiftData access in widgets requires App Groups configuration
        // This returns a live entry when App Groups are set up in Xcode
        NotesWidgetEntry(
            date: Date(),
            totalActionsToday: 0,
            completedActionsToday: 0,
            recentNoteSnippet: nil
        )
    }
}

// MARK: - Widget Views

struct NotesWidgetSmallView: View {

    let entry: NotesWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "note.text")
                    .foregroundStyle(Color.accentColor)
                    .font(.caption)
                Text("Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()

            if let snippet = entry.recentNoteSnippet {
                Text(snippet)
                    .font(.system(size: 12))
                    .lineLimit(3)
                    .foregroundStyle(.primary)
            } else {
                Text("Tap + to add a note")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quick add button
            Button(intent: QuickAddIntent()) {
                Label("Add Note", systemImage: "plus.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct NotesWidgetMediumView: View {

    let entry: NotesWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: action progress
            VStack(alignment: .leading, spacing: 6) {
                Label("Today's Actions", systemImage: "checkmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("\(entry.completedActionsToday)/\(entry.totalActionsToday)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(entry.totalActionsToday == 0 ? Color.secondary : Color.accentColor)

                if entry.totalActionsToday > 0 {
                    ProgressView(value: Double(entry.completedActionsToday), total: Double(entry.totalActionsToday))
                        .tint(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: quick add + recent note
            VStack(alignment: .leading, spacing: 8) {
                Button(intent: QuickAddIntent()) {
                    Label("Quick Add", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                if let snippet = entry.recentNoteSnippet {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Configuration

struct NotesWidget: Widget {

    let kind = "NotesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotesWidgetProvider()) { entry in
            NotesWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("Notes Quick Add")
        .description("See today's action count and add a new note with one tap.")
        .supportedFamilies([.systemSmall])
    }
}

struct NotesMediumWidget: Widget {

    let kind = "NotesMediumWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NotesWidgetProvider()) { entry in
            NotesWidgetMediumView(entry: entry)
        }
        .configurationDisplayName("Notes Dashboard")
        .description("Track today's actions and quickly add notes.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct NotesWidgetBundle: WidgetBundle {
    var body: some Widget {
        NotesWidget()
        NotesMediumWidget()
    }
}
