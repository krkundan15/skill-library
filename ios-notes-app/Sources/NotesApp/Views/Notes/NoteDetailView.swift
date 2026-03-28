import SwiftUI
import SwiftData
import NotesShared

struct NoteDetailView: View {

    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var orchestrator: AIOrchestrator
    @State private var showDeleteConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Category + timestamp header
                HStack {
                    Label(note.category.displayName, systemImage: note.category.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(note.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(note.category.color.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(DateFormatters.full.string(from: note.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if note.updatedAt > note.createdAt {
                            Text("Updated \(DateFormatters.relative(note.updatedAt))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                Divider()

                // Full note content
                Text(note.content)
                    .font(.body)
                    .foregroundStyle(AppColor.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // AI Summary section
                if note.isProcessed, let summary = note.summary {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Summary", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(AppColor.primaryText)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accentColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                } else if !note.isProcessed {
                    HStack {
                        ProgressView()
                        Text("AI is analysing your note…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Action Items section
                if !note.actionItems.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Action Items", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(note.actionItems) { item in
                            ActionItemRowView(item: item)
                        }
                    }
                }

                // Re-process button
                if note.isProcessed {
                    Button {
                        note.isProcessed = false
                        note.summary = nil
                        Task {
                            await orchestrator.process(note: note, modelContext: modelContext)
                        }
                    } label: {
                        Label("Re-analyse with AI", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(AppColor.background)
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete this note?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(note)
                try? modelContext.save()
                dismiss()
            }
        }
    }
}
