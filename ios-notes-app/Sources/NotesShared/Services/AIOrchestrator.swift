import Foundation
import Network
import SwiftData

/// Coordinates AI processing: uses Claude API when online, falls back to on-device NLP.
@MainActor
public final class AIOrchestrator: ObservableObject {

    @Published public var isProcessing: Bool = false
    @Published public var lastError: String?

    private let onDevice = OnDeviceNLPService()
    private let monitor = NWPathMonitor()
    private var isOnline: Bool = false
    private var apiKey: String { KeychainHelper.load(key: "claude_api_key") ?? "" }

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

    /// Processes the note: writes summary and action items back to SwiftData.
    public func process(note: Note, modelContext: ModelContext) async {
        guard !note.content.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isProcessing = true
        lastError = nil
        defer { isProcessing = false }

        let result: AIProcessingResult

        if isOnline && !apiKey.isEmpty {
            do {
                result = try await ClaudeAPIService(apiKey: apiKey).process(noteContent: note.content)
            } catch {
                lastError = error.localizedDescription
                // Fall back to on-device
                result = onDevice.process(noteContent: note.content)
            }
        } else {
            result = onDevice.process(noteContent: note.content)
        }

        // Write results back on main actor (SwiftData context)
        note.summary = result.summary
        note.isProcessed = true

        for actionTitle in result.actions where !actionTitle.isEmpty {
            let item = ActionItem(title: actionTitle, note: note)
            modelContext.insert(item)
            note.actionItems.append(item)
        }

        note.updatedAt = Date()

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
