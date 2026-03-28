import Foundation

/// Response decoded from Claude's structured JSON output
public struct AIProcessingResult: Sendable {
    public let summary: String
    public let actions: [String]

    public init(summary: String, actions: [String]) {
        self.summary = summary
        self.actions = actions
    }
}

/// Calls the Anthropic Messages API to summarise a note and extract action items.
public final class ClaudeAPIService: Sendable {

    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let model = "claude-haiku-4-5"

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func process(noteContent: String) async throws -> AIProcessingResult {
        let systemPrompt = """
        You are a personal assistant helping organise notes. \
        Given a note, return ONLY valid JSON (no markdown, no extra text) in this exact format:
        {"summary":"<one sentence summary>","actions":["<action 1>","<action 2>"]}
        Extract concrete action items (tasks to do). If there are none, return an empty array.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 512,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": noteContent]
            ]
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw ClaudeAPIError.httpError(status)
        }

        return try parseResponse(data: data)
    }

    private func parseResponse(data: Data) throws -> AIProcessingResult {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            throw ClaudeAPIError.unexpectedResponseFormat
        }

        // Claude returns JSON inside the text field
        guard
            let jsonData = text.data(using: .utf8),
            let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let summary = parsed["summary"] as? String,
            let actions = parsed["actions"] as? [String]
        else {
            throw ClaudeAPIError.invalidJSONContent(text)
        }

        return AIProcessingResult(summary: summary, actions: actions)
    }
}

public enum ClaudeAPIError: LocalizedError {
    case httpError(Int)
    case unexpectedResponseFormat
    case invalidJSONContent(String)

    public var errorDescription: String? {
        switch self {
        case .httpError(let code): return "API error (HTTP \(code))"
        case .unexpectedResponseFormat: return "Unexpected API response format"
        case .invalidJSONContent(let text): return "Could not parse AI response: \(text.prefix(100))"
        }
    }
}
