import SwiftUI
import SwiftData
import NotesShared

struct QuickCaptureView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var orchestrator: AIOrchestrator

    @State private var text = ""
    @State private var category: NoteCategory = .personal
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Category picker
                    Picker("Category", selection: $category) {
                        ForEach(NoteCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Timestamp
                    Text(DateFormatters.full.string(from: Date()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    // Text input
                    TextEditor(text: $text)
                        .focused($isFocused)
                        .frame(minHeight: 160)
                        .padding(12)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("What's on your mind?")
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 28)
                                    .padding(.top, 20)
                                    .allowsHitTesting(false)
                            }
                        }

                    // Voice recorder
                    VoiceRecorderView { transcription, _ in
                        if text.isEmpty {
                            text = transcription
                        } else {
                            text += "\n" + transcription
                        }
                    }
                }
                .padding(.top)
            }
            .background(AppColor.background)
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let note = Note(content: trimmed, category: category)
        modelContext.insert(note)
        try? modelContext.save()

        dismiss()

        // Process with AI in background
        Task {
            await orchestrator.process(note: note, modelContext: modelContext)
        }
    }
}
