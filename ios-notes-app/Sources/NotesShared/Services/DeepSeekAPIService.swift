import Foundation

/// Calls the DeepSeek Chat Completions API (OpenAI-compatible) to summarise
/// notes and meeting transcripts and extract action items.
public final class DeepSeekAPIService: AIProvider {

    private let apiKey: String
    private let baseURL = URL(string: "https://api.deepseek.com/chat/completions")!
    private let model = "deepseek-chat"

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

        let text = try await sendMessage(system: systemPrompt, user: noteContent)

        guard
            let jsonData = text.data(using: .utf8),
            let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let summary = parsed["summary"] as? String,
            let actions = parsed["actions"] as? [String]
        else {
            throw DeepSeekAPIError.invalidJSONContent(text)
        }

        return AIProcessingResult(summary: summary, actions: actions)
    }

    public func processMeeting(transcript: String) async throws -> MeetingProcessingResult {
        let systemPrompt = """
        You are an assistant that turns meeting transcripts into a clear, actionable summary. \
        Given a raw meeting transcript, return ONLY valid JSON (no markdown, no extra text) in this exact format:
        {"summary":"<2-3 sentence overview of the meeting>","keyPoints":["<key discussion point>"],"decisions":["<decision made>"],"actions":["<concrete follow-up action>"]}
        Keep each array item short (under 20 words). If a category has nothing relevant, return an empty array for it.
        """

        let text = try await sendMessage(system: systemPrompt, user: transcript, maxTokens: 1024)

        guard
            let jsonData = text.data(using: .utf8),
            let parsed = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let summary = parsed["summary"] as? String,
            let keyPoints = parsed["keyPoints"] as? [String],
            let decisions = parsed["decisions"] as? [String],
            let actions = parsed["actions"] as? [String]
        else {
            throw DeepSeekAPIError.invalidJSONContent(text)
        }

        return MeetingProcessingResult(summary: summary, keyPoints: keyPoints, decisions: decisions, actions: actions)
    }

    // MARK: - Private

    private func sendMessage(system: String, user: String, maxTokens: Int = 512) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": system],
                ["role": "user", "content": user]
            ]
        ]

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw DeepSeekAPIError.httpError(status)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let text = message["content"] as? String
        else {
            throw DeepSeekAPIError.unexpectedResponseFormat
        }

        return text
    }
}

public enum DeepSeekAPIError: LocalizedError {
    case httpError(Int)
    case unexpectedResponseFormat
    case invalidJSONContent(String)

    public var errorDescription: String? {
        switch self {
        case .httpError(let code): return "DeepSeek API error (HTTP \(code))"
        case .unexpectedResponseFormat: return "Unexpected DeepSeek response format"
        case .invalidJSONContent(let text): return "Could not parse DeepSeek response: \(text.prefix(100))"
        }
    }
}
