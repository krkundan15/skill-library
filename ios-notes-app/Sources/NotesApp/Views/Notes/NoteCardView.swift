import SwiftUI
import NotesShared

struct NoteCardView: View {

    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: category badge + timestamp
            HStack {
                Label(note.category.displayName, systemImage: note.category.icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(note.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(note.category.color.opacity(0.12))
                    .clipShape(Capsule())

                if note.noteType == .meeting {
                    Label(note.formattedDuration ?? "", systemImage: "mic.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(DateFormatters.relative(note.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Content snippet
            Text(note.snippet)
                .font(note.noteType == .meeting ? .body.weight(.semibold) : .body)
                .foregroundStyle(AppColor.primaryText)
                .lineLimit(note.noteType == .meeting ? 1 : 3)

            // Summary if available
            if let summary = note.summary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .lineLimit(2)
            }

            // Action item count badge
            if !note.actionItems.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                    Text("\(note.actionItems.count) action\(note.actionItems.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(AppColor.pendingAction)
            }

            // Processing indicator
            if !note.isProcessed {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Analysing…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
