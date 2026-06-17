import Foundation
import Network
import SwiftData

/// Coordinates AI processing: routes to the user-selected provider (Claude or
/// DeepSeek) when online, and always falls back to on-device NLP if the
/// network is unavailable, no key is configured, or the request fails.
@MainActor
public final class AIOrchestrator: ObservableObject {

    @Published public var isProcessing: Bool = false
    @Published public var lastError: String?

    private let onDevice = OnDeviceNLPService()
    private let monitor = NWPathMonitor()
    private var isOnline: Bool = false

    /// Provider the user picked in Settings. Defaults to Claude.
    public var selectedProviderKind: AIProviderKind {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "aiProviderKind"),
                  let kind = AIProviderKind(rawValue: raw)
            else { return .claude }
            return kind
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "aiProviderKind") }
    }

    public init() {
        let queue = DispatchQueue(label: "network.monitor")
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Processes a short quick-captured note: writes summary and action items back to SwiftData.
    public func process(note: Note, modelContext: ModelContext) async {
        guard !note.content.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        let result = await summarise(text: note.content)

        note.summary = result.summary
        note.isProcessed = true

        for actionTitle in result.actions where !actionTitle.isEmpty {
            let item = ActionItem(title: actionTitle, note: note)
            modelContext.insert(item)
            note.actionItems.append(item)
        }

        note.updatedAt = Date()
        save(modelContext)
    }

    /// Processes a meeting transcript: writes overview, key points, decisions
    /// and action items back to SwiftData.
    public func processMeeting(note: Note, modelContext: ModelContext) async {
        guard let transcript = note.transcript, !transcript.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        let result: MeetingProcessingResult

        if let provider = currentProvider() {
            do {
                result = try await provider.processMeeting(transcript: transcript)
            } catch {
                lastError = error.localizedDescription
                result = onDevice.processMeeting(transcript: transcript)
            }
        } else {
            result = onDevice.processMeeting(transcript: transcript)
        }

        note.summary = result.summary
        note.keyPoints = result.keyPoints
        note.decisions = result.decisions
        note.isProcessed = true

        for actionTitle in result.actions where !actionTitle.isEmpty {
            let item = ActionItem(title: actionTitle, note: note)
            modelContext.insert(item)
            note.actionItems.append(item)
        }

        note.updatedAt = Date()
        save(modelContext)
    }

    // MARK: - Private

    private func summarise(text: String) async -> AIProcessingResult {
        guard let provider = currentProvider() else {
            return onDevice.process(noteContent: text)
        }
        do {
            return try await provider.process(noteContent: text)
        } catch {
            lastError = error.localizedDescription
            return onDevice.process(noteContent: text)
        }
    }

    /// Returns a live provider instance only when online and a key is configured
    /// for the user's selected provider; otherwise nil (signals on-device fallback).
    private func currentProvider() -> AIProvider? {
        guard isOnline else { return nil }
        let kind = selectedProviderKind
        guard let keychainKey = kind.keychainKey,
              let apiKey = KeychainHelper.load(key: keychainKey),
              !apiKey.isEmpty
        else { return nil }

        switch kind {
        case .claude: return ClaudeAPIService(apiKey: apiKey)
        case .deepseek: return DeepSeekAPIService(apiKey: apiKey)
        case .onDevice: return nil
        }
    }

    private func save(_ modelContext: ModelContext) {
        do {
            try modelContext.save()
        } catch {
            lastError = "Failed to save: \(error.localizedDescription)"
        }
    }
}

// MARK: - Keychain helper

public enum KeychainHelper {

    public static func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    public static func load(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var item: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func delete(key: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
