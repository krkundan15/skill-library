import Foundation

/// Structured result for a transcribed meeting: overview, discussion points,
/// decisions made, and concrete follow-up actions.
public struct MeetingProcessingResult: Sendable {
    public let summary: String
    public let keyPoints: [String]
    public let decisions: [String]
    public let actions: [String]

    public init(summary: String, keyPoints: [String], decisions: [String], actions: [String]) {
        self.summary = summary
        self.keyPoints = keyPoints
        self.decisions = decisions
        self.actions = actions
    }
}

/// Common interface implemented by every online AI backend (Claude, DeepSeek, …)
/// so `AIOrchestrator` can swap providers without changing call sites.
public protocol AIProvider: Sendable {
    /// Summarise a short note and extract any action items.
    func process(noteContent: String) async throws -> AIProcessingResult

    /// Summarise a full meeting transcript into an overview, key points,
    /// decisions, and action items.
    func processMeeting(transcript: String) async throws -> MeetingProcessingResult
}

/// Identifies which backend the user has selected in Settings.
public enum AIProviderKind: String, CaseIterable, Sendable {
    case claude
    case deepseek
    case onDevice

    public var displayName: String {
        switch self {
        case .claude: return "Claude"
        case .deepseek: return "DeepSeek"
        case .onDevice: return "On-device only"
        }
    }

    /// Keychain key under which this provider's API key is stored.
    public var keychainKey: String? {
        switch self {
        case .claude: return "claude_api_key"
        case .deepseek: return "deepseek_api_key"
        case .onDevice: return nil
        }
    }
}
