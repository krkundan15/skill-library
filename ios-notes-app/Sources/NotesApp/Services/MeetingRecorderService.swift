import Foundation
import AVFoundation
import Speech

/// Records long-form audio (meetings) continuously to disk while producing an
/// unbroken live transcript.
///
/// `SFSpeechRecognizer` enforces roughly a 1-minute limit per recognition
/// request, which would normally cut a transcript off mid-meeting. This
/// service works around that by cycling the recognition *request* every
/// `chunkInterval` seconds while the underlying `AVAudioEngine` tap keeps
/// running the entire time — so the recording itself, and the stitched
/// transcript, never have a gap.
@MainActor
public final class MeetingRecorderService: NSObject, ObservableObject {

    public enum RecorderState: Equatable {
        case idle, recording, paused, stopped
    }

    @Published public private(set) var state: RecorderState = .idle
    @Published public private(set) var elapsed: TimeInterval = 0
    @Published public private(set) var liveTranscript: String = ""
    @Published public var errorMessage: String?

    public private(set) var audioFileURL: URL?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: .current)
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioFile: AVAudioFile?

    /// Transcript text from chunks that have already been finalised.
    private var finalizedTranscript = ""
    /// Live partial text from the chunk currently in flight.
    private var pendingChunkText = ""

    private var chunkTimer: Timer?
    private var elapsedTimer: Timer?
    /// Restart recognition just under Apple's ~60s single-request cap.
    private let chunkInterval: TimeInterval = 50

    // MARK: - Public controls

    public func start() {
        guard state == .idle || state == .stopped else { return }
        errorMessage = nil
        finalizedTranscript = ""
        pendingChunkText = ""
        liveTranscript = ""
        elapsed = 0

        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                guard authStatus == .authorized else {
                    self?.errorMessage = "Speech recognition not authorised. Enable it in Settings."
                    return
                }
                self?.beginRecording()
            }
        }
    }

    public func pause() {
        guard state == .recording else { return }
        audioEngine.pause()
        chunkTimer?.invalidate()
        elapsedTimer?.invalidate()
        finishCurrentRecognitionChunk(startNewChunk: false)
        state = .paused
    }

    public func resume() {
        guard state == .paused else { return }
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Could not resume recording: \(error.localizedDescription)"
            return
        }
        startNewRecognitionChunk()
        startTimers()
        state = .recording
    }

    /// Stops recording and returns the full stitched transcript, saved audio file, and duration.
    @discardableResult
    public func stop() -> (transcript: String, audioURL: URL?, duration: TimeInterval) {
        chunkTimer?.invalidate()
        elapsedTimer?.invalidate()
        chunkTimer = nil
        elapsedTimer = nil

        finishCurrentRecognitionChunk(startNewChunk: false)

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioFile = nil

        state = .stopped
        return (finalizedTranscript.trimmingCharacters(in: .whitespacesAndNewlines), audioFileURL, elapsed)
    }

    // MARK: - Private

    private func beginRecording() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("meeting-\(UUID().uuidString).m4a")
        audioFileURL = fileURL

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        do {
            audioFile = try AVAudioFile(forWriting: fileURL, settings: recordingFormat.settings)
        } catch {
            errorMessage = "Could not create audio file: \(error.localizedDescription)"
            return
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self else { return }
            try? self.audioFile?.write(from: buffer)
            self.recognitionRequest?.append(buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
            return
        }

        startNewRecognitionChunk()
        startTimers()
        state = .recording
    }

    private func startTimers() {
        chunkTimer = Timer.scheduledTimer(withTimeInterval: chunkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.finishCurrentRecognitionChunk(startNewChunk: true) }
        }
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsed += 1 }
        }
    }

    private func startNewRecognitionChunk() {
        pendingChunkText = ""
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.pendingChunkText = result.bestTranscription.formattedString
                    self.liveTranscript = (self.finalizedTranscript + " " + self.pendingChunkText)
                        .trimmingCharacters(in: .whitespaces)
                }
                if let error {
                    // Cancelling the previous chunk on restart always raises a benign
                    // "Cancelled" error here — ignore it rather than surfacing it to the user.
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// Finalises the current ~50s recognition chunk (folding its text into
    /// `finalizedTranscript`) and, if requested, immediately starts the next
    /// chunk so the live transcript keeps flowing without a gap.
    private func finishCurrentRecognitionChunk(startNewChunk: Bool) {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        if !pendingChunkText.isEmpty {
            finalizedTranscript = (finalizedTranscript + " " + pendingChunkText)
                .trimmingCharacters(in: .whitespaces)
        }
        pendingChunkText = ""
        recognitionRequest = nil
        recognitionTask = nil

        if startNewChunk {
            startNewRecognitionChunk()
        }
    }
}
