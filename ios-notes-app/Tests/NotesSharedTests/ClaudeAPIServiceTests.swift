import XCTest
@testable import NotesShared

final class ClaudeAPIServiceTests: XCTestCase {

    func testAIProcessingResultInitialises() {
        let result = AIProcessingResult(
            summary: "Call the dentist tomorrow",
            actions: ["Schedule dentist appointment", "Pick up prescription"]
        )

        XCTAssertEqual(result.summary, "Call the dentist tomorrow")
        XCTAssertEqual(result.actions.count, 2)
        XCTAssertEqual(result.actions[0], "Schedule dentist appointment")
    }

    func testOnDeviceNLPServiceProducesResult() {
        let service = OnDeviceNLPService()
        let result = service.process(noteContent: "Need to call John about the project. Review the budget document.")

        XCTAssertFalse(result.summary.isEmpty)
        // Actions may be empty on some platforms depending on NLTagger availability
        XCTAssertNotNil(result.actions)
    }

    func testOnDeviceNLPSummaryUsesFirstSentence() {
        let service = OnDeviceNLPService()
        let result = service.process(noteContent: "First sentence. Second sentence. Third sentence.")
        XCTAssertEqual(result.summary, "First sentence")
    }

    func testOnDeviceNLPHandlesEmptyInput() {
        let service = OnDeviceNLPService()
        let result = service.process(noteContent: "   ")
        // Should not crash; summary may be empty or whitespace
        XCTAssertNotNil(result.summary)
    }

    func testClaudeAPIErrorDescriptions() {
        XCTAssertNotNil(ClaudeAPIError.httpError(401).errorDescription)
        XCTAssertNotNil(ClaudeAPIError.unexpectedResponseFormat.errorDescription)
        XCTAssertNotNil(ClaudeAPIError.invalidJSONContent("bad json").errorDescription)
    }

    func testKeychainHelperSaveAndLoad() {
        let key = "test_key_\(UUID().uuidString)"
        let value = "test_value_123"

        KeychainHelper.save(key: key, value: value)
        let loaded = KeychainHelper.load(key: key)
        XCTAssertEqual(loaded, value)

        KeychainHelper.delete(key: key)
        let afterDelete = KeychainHelper.load(key: key)
        XCTAssertNil(afterDelete)
    }

    func testMeetingProcessingResultInitialises() {
        let result = MeetingProcessingResult(
            summary: "Team discussed Q3 roadmap.",
            keyPoints: ["Budget needs review", "Hiring plan delayed"],
            decisions: ["Ship feature X next sprint"],
            actions: ["Send budget doc to finance"]
        )

        XCTAssertEqual(result.summary, "Team discussed Q3 roadmap.")
        XCTAssertEqual(result.keyPoints.count, 2)
        XCTAssertEqual(result.decisions, ["Ship feature X next sprint"])
        XCTAssertEqual(result.actions, ["Send budget doc to finance"])
    }

    func testDeepSeekAPIErrorDescriptions() {
        XCTAssertNotNil(DeepSeekAPIError.httpError(429).errorDescription)
        XCTAssertNotNil(DeepSeekAPIError.unexpectedResponseFormat.errorDescription)
        XCTAssertNotNil(DeepSeekAPIError.invalidJSONContent("bad json").errorDescription)
    }

    func testAIProviderKindDisplayNames() {
        XCTAssertEqual(AIProviderKind.claude.displayName, "Claude")
        XCTAssertEqual(AIProviderKind.deepseek.displayName, "DeepSeek")
        XCTAssertEqual(AIProviderKind.onDevice.displayName, "On-device only")
    }

    func testAIProviderKindKeychainKeys() {
        XCTAssertEqual(AIProviderKind.claude.keychainKey, "claude_api_key")
        XCTAssertEqual(AIProviderKind.deepseek.keychainKey, "deepseek_api_key")
        XCTAssertNil(AIProviderKind.onDevice.keychainKey)
    }

    func testOnDeviceNLPServiceProcessesMeeting() {
        let service = OnDeviceNLPService()
        let transcript = "We reviewed the budget. Sales grew this quarter. Next we need a hiring plan. Marketing wants a new campaign. Engineering is blocked on infra. Let's also revisit the roadmap."
        let result = service.processMeeting(transcript: transcript)

        XCTAssertFalse(result.summary.isEmpty)
        XCTAssertTrue(result.decisions.isEmpty)
        XCTAssertLessThanOrEqual(result.keyPoints.count, 5)
    }

    func testOnDeviceNLPServiceMeetingHandlesEmptyTranscript() {
        let service = OnDeviceNLPService()
        let result = service.processMeeting(transcript: "   ")
        XCTAssertNotNil(result.summary)
        XCTAssertTrue(result.keyPoints.isEmpty)
    }
}
