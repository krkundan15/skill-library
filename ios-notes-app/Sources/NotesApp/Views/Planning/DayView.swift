import SwiftUI
import SwiftData
import NotesShared

struct DayView: View {

    @Binding var date: Date
    @Query(sort: \Note.createdAt, order: .reverse) private var allNotes: [Note]

    private var dayNotes: [Note] {
        let (start, end) = DateFormatters.dayBounds(for: date)
        return allNotes.filter { $0.createdAt >= start && $0.createdAt < end }
    }

    private var personalNotes: [Note] { dayNotes.filter { $0.category == .personal } }
    private var workNotes: [Note]     { dayNotes.filter { $0.category == .work } }

    var body: some View {
        VStack(spacing: 0) {
            // Date navigation
            HStack {
                Button {
                    date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
                } label: {
                    Image(systemName: "chevron.left")
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(DateFormatters.full.string(from: date).components(separatedBy: ",").first ?? "")
                        .font(.headline)
                    if Calendar.current.isDateInToday(date) {
                        Text("Today")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Spacer()

                Button {
                    date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if dayNotes.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        categorySection(title: "Personal", icon: "person.fill", color: NoteCategory.personal.color, notes: personalNotes)
                        categorySection(title: "Work", icon: "briefcase.fill", color: NoteCategory.work.color, notes: workNotes)
                    }
                    .padding()
                }
            }
        }
    }

    @ViewBuilder
    private func categorySection(title: String, icon: String, color: Color, notes: [Note]) -> some View {
        if !notes.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)

                ForEach(notes) { note in
                    NavigationLink(destination: NoteDetailView(note: note)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(DateFormatters.time.string(from: note.createdAt))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if !note.actionItems.isEmpty {
                                    Text("\(note.actionItems.count) actions")
                                        .font(.caption)
                                        .foregroundStyle(AppColor.pendingAction)
                                }
                            }
                            Text(note.snippet)
                                .font(.subheadline)
                                .foregroundStyle(AppColor.primaryText)
                                .lineLimit(2)

                            // Show action items inline
                            ForEach(note.actionItems.prefix(3)) { item in
                                ActionItemRowView(item: item)
                            }
                        }
                        .padding(12)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("No notes on this day")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
