import SwiftUI
import SwiftData
import NotesShared

struct NoteDetailView: View {

    @Bindable var note: Note
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var orchestrator: AIOrchestrator
    @State private var showDeleteConfirm = false
    @State private var showTranscript = false
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

                    if note.noteType == .meeting, let duration = note.formattedDuration {
                        Label(duration, systemImage: "mic.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                    }

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

                // Title / content
                Text(note.content)
                    .font(note.noteType == .meeting ? .title3.weight(.semibold) : .body)
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

                // Key points (meeting only)
                if !note.keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Key Points", systemImage: "list.bullet")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(note.keyPoints, id: \.self) { point in
                            bulletRow(point)
                        }
                    }
                }

                // Decisions (meeting only)
                if !note.decisions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Decisions", systemImage: "checkmark.seal")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(note.decisions, id: \.self) { decision in
                            bulletRow(decision)
                        }
                    }
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

                // Full transcript (meeting only)
                if let transcript = note.transcript, !transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            withAnimation { showTranscript.toggle() }
                        } label: {
                            Label("Full Transcript", systemImage: showTranscript ? "chevron.down" : "chevron.right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        if showTranscript {
                            Text(transcript)
                                .font(.subheadline)
                                .foregroundStyle(AppColor.primaryText)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColor.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                // Re-process button
                if note.isProcessed {
                    Button {
                        note.isProcessed = false
                        note.summary = nil
                        Task {
                            if note.noteType == .meeting {
                                await orchestrator.processMeeting(note: note, modelContext: modelContext)
                            } else {
                                await orchestrator.process(note: note, modelContext: modelContext)
                            }
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

    private func bulletRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(AppColor.primaryText.opacity(0.4))
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AppColor.primaryText)
        }
    }
}
