import SwiftUI
import SwiftData
import NotesShared

/// Records a meeting end-to-end: live transcript while recording, then hands
/// the full transcript off to AIOrchestrator for a summary, key points,
/// decisions, and action items once the user stops.
struct MeetingCaptureView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var orchestrator: AIOrchestrator
    @StateObject private var recorder = MeetingRecorderService()

    @State private var title = ""
    @State private var category: NoteCategory = .work
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                VStack(alignment: .leading, spacing: 12) {
                    TextField("Meeting title", text: $title)
                        .focused($titleFocused)
                        .font(.title3.weight(.semibold))
                        .padding(12)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Picker("Category", selection: $category) {
                        ForEach(NoteCategory.allCases, id: \.self) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .disabled(recorder.state == .recording || recorder.state == .paused)

                Text(formattedElapsed)
                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(recorder.state == .recording ? .red : AppColor.primaryText)

                if recorder.state == .recording {
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 4, height: CGFloat.random(in: 8...28))
                                .animation(
                                    .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.1),
                                    value: recorder.elapsed
                                )
                        }
                    }
                    .frame(height: 28)
                }

                ScrollView {
                    Text(recorder.liveTranscript.isEmpty
                         ? "Transcript will appear here as you speak…"
                         : recorder.liveTranscript)
                        .font(.subheadline)
                        .foregroundStyle(recorder.liveTranscript.isEmpty ? .tertiary : AppColor.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxHeight: 220)
                .background(AppColor.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                if let error = recorder.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                Spacer()

                controlButtons
                    .padding(.bottom, 24)
            }
            .padding(.top)
            .background(AppColor.background)
            .navigationTitle("New Meeting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        _ = recorder.stop()
                        dismiss()
                    }
                }
            }
            .onAppear { titleFocused = true }
        }
    }

    private var formattedElapsed: String {
        let total = Int(recorder.elapsed)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }

    @ViewBuilder
    private var controlButtons: some View {
        switch recorder.state {
        case .idle, .stopped:
            Button {
                titleFocused = false
                recorder.start()
            } label: {
                Label("Start Recording", systemImage: "record.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

        case .recording:
            HStack(spacing: 16) {
                Button {
                    recorder.pause()
                } label: {
                    Label("Pause", systemImage: "pause.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColor.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(role: .destructive) {
                    finishMeeting()
                } label: {
                    Label("Stop & Summarise", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)

        case .paused:
            HStack(spacing: 16) {
                Button {
                    recorder.resume()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Button(role: .destructive) {
                    finishMeeting()
                } label: {
                    Label("Stop & Summarise", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal)
        }
    }

    private func finishMeeting() {
        let result = recorder.stop()
        guard !result.transcript.isEmpty else {
            dismiss()
            return
        }

        let noteTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? "Meeting — \(DateFormatters.full.string(from: Date()))"
            : title.trimmingCharacters(in: .whitespaces)

        let note = Note(
            content: noteTitle,
            category: category,
            audioFileURL: result.audioURL?.lastPathComponent,
            noteType: .meeting,
            transcript: result.transcript,
            duration: result.duration
        )
        modelContext.insert(note)
        try? modelContext.save()

        dismiss()

        Task {
            await orchestrator.processMeeting(note: note, modelContext: modelContext)
        }
    }
}
