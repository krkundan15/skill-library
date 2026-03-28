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
}
