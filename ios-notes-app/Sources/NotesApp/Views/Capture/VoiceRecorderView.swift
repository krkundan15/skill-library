import SwiftUI
import AVFoundation
import Speech

/// Handles microphone recording and speech transcription.
/// Calls `onTranscription` with the recognised text when recording stops.
struct VoiceRecorderView: View {

    let onTranscription: (String, String?) -> Void  // (text, audioFilePath)

    @State private var isRecording = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var transcribedText = ""
    @State private var error: String?

    private let speechRecognizer = SFSpeechRecognizer(locale: .current)

    var body: some View {
        VStack(spacing: 12) {
            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                Label(
                    isRecording ? "Stop Recording" : "Record Voice Note",
                    systemImage: isRecording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .font(.headline)
                .foregroundStyle(isRecording ? .red : .accentColor)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isRecording ? Color.red.opacity(0.1) : Color.accentColor.opacity(0.1))
                )
                .padding(.horizontal)
            }

            if isRecording {
                HStack(spacing: 4) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.red)
                            .frame(width: 4, height: CGFloat.random(in: 8...24))
                            .animation(
                                .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.1),
                                value: isRecording
                            )
                    }
                }
            }
        }
        .onDisappear {
            if isRecording { stopRecording() }
        }
    }

    // MARK: - Recording

    private func startRecording() {
        error = nil
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    self.error = "Speech recognition not authorised. Please enable in Settings."
                    return
                }
                self.beginRecording()
            }
        }
    }

    private func beginRecording() {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { result, err in
            if let result {
                DispatchQueue.main.async { transcribedText = result.bestTranscription.formattedString }
            }
            if let err {
                DispatchQueue.main.async { self.error = err.localizedDescription }
            }
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
        } catch {
            self.error = "Could not start recording: \(error.localizedDescription)"
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionTask?.finish()
        recognitionTask = nil
        isRecording = false

        if !transcribedText.isEmpty {
            onTranscription(transcribedText, nil)
            transcribedText = ""
        }
    }
}
