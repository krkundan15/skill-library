import XCTest
@testable import NotesShared

final class NoteModelTests: XCTestCase {

    func testNoteInitialisesWithDefaults() {
        let note = Note(content: "Test note content", category: .personal)

        XCTAssertFalse(note.id.uuidString.isEmpty)
        XCTAssertEqual(note.content, "Test note content")
        XCTAssertEqual(note.category, .personal)
        XCTAssertNil(note.summary)
        XCTAssertFalse(note.isProcessed)
        XCTAssertTrue(note.actionItems.isEmpty)
        XCTAssertNil(note.audioFileURL)
    }

    func testNoteSnippetTruncatesLongContent() {
        let longContent = String(repeating: "a", count: 200)
        let note = Note(content: longContent, category: .work)

        XCTAssertEqual(note.snippet.count, 121) // 120 chars + "…"
        XCTAssertTrue(note.snippet.hasSuffix("…"))
    }

    func testNoteSnippetReturnsShortContentUnchanged() {
        let short = "Short note"
        let note = Note(content: short, category: .personal)
        XCTAssertEqual(note.snippet, short)
    }

    func testNoteCategoryDisplayNames() {
        XCTAssertEqual(NoteCategory.personal.displayName, "Personal")
        XCTAssertEqual(NoteCategory.work.displayName, "Work")
    }

    func testNoteCategoryIcons() {
        XCTAssertEqual(NoteCategory.personal.icon, "person.fill")
        XCTAssertEqual(NoteCategory.work.icon, "briefcase.fill")
    }

    func testActionItemDefaultsToIncomplete() {
        let item = ActionItem(title: "Buy milk")
        XCTAssertFalse(item.isCompleted)
        XCTAssertNil(item.dueDate)
        XCTAssertNil(item.note)
    }

    func testActionItemBucketWithoutDueDate() {
        let item = ActionItem(title: "Someday task")
        XCTAssertEqual(item.bucket, .upcoming)
    }

    func testActionItemBucketWhenCompleted() {
        let item = ActionItem(title: "Done task")
        item.isCompleted = true
        XCTAssertEqual(item.bucket, .done)
    }
}
