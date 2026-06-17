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

    func testNoteDefaultsToQuickType() {
        let note = Note(content: "Quick note", category: .personal)
        XCTAssertEqual(note.noteType, .quick)
        XCTAssertNil(note.transcript)
        XCTAssertNil(note.duration)
        XCTAssertTrue(note.keyPoints.isEmpty)
        XCTAssertTrue(note.decisions.isEmpty)
        XCTAssertNil(note.formattedDuration)
    }

    func testNoteInitialisesAsMeeting() {
        let note = Note(
            content: "Standup",
            category: .work,
            noteType: .meeting,
            transcript: "We discussed the roadmap.",
            duration: 95
        )
        XCTAssertEqual(note.noteType, .meeting)
        XCTAssertEqual(note.transcript, "We discussed the roadmap.")
        XCTAssertEqual(note.duration, 95)
    }

    func testFormattedDurationUnderAnHour() {
        let note = Note(content: "Standup", category: .work, noteType: .meeting, duration: 125)
        XCTAssertEqual(note.formattedDuration, "2:05")
    }

    func testFormattedDurationOverAnHour() {
        let note = Note(content: "Workshop", category: .work, noteType: .meeting, duration: 3725)
        XCTAssertEqual(note.formattedDuration, "1:02:05")
    }

    func testNoteTypeDisplayNamesAndIcons() {
        XCTAssertEqual(NoteType.quick.displayName, "Note")
        XCTAssertEqual(NoteType.meeting.displayName, "Meeting")
        XCTAssertEqual(NoteType.quick.icon, "note.text")
        XCTAssertEqual(NoteType.meeting.icon, "person.2.wave.2.fill")
    }
}
