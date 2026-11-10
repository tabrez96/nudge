import XCTest
@testable import NudgeCore

final class MeetingNotesTests: XCTestCase {
    func testNilAndBlank() {
        XCTAssertNil(MeetingNotes.summary(nil))
        XCTAssertNil(MeetingNotes.summary(""))
        XCTAssertNil(MeetingNotes.summary("  \n "))
    }

    func testPlainTextCollapsed() {
        XCTAssertEqual(MeetingNotes.summary("Agenda:\n\n  launch   checklist"), "Agenda: launch checklist")
    }

    func testHTMLStripped() {
        XCTAssertEqual(MeetingNotes.summary("<p>Renewal&nbsp;check-in</p><br>Bring &amp; share"),
                       "Renewal check-in Bring & share")
    }

    func testGoogleMeetBoilerplateRemoved() {
        let notes = "Agenda: launch\n\nJoin with Google Meet: https://meet.google.com/abc\nJoin by phone\n"
            + "(US) +1 555-010-0199 PIN: 123#\nMore phone numbers: https://tel.meet/abc"
        XCTAssertEqual(MeetingNotes.summary(notes), "Agenda: launch")
    }

    func testGoogleFooterDropped() {
        XCTAssertEqual(MeetingNotes.summary("Hi\n-::~:~::~:~::-\nAnything after"), "Hi")
    }

    func testZoomBoilerplateRemoved() {
        XCTAssertNil(MeetingNotes.summary("Join Zoom Meeting\nhttps://zoom.us/j/1\n\nMeeting ID: 123 456\nPasscode: 9"))
    }

    func testLinkOnlyAndSeparatorLinesRemoved() {
        XCTAssertEqual(MeetingNotes.summary("https://example.com\n────────\nNotes here"), "Notes here")
    }

    func testLongNotesCapped() {
        let result = MeetingNotes.summary(String(repeating: "a ", count: 500))
        XCTAssertEqual(result?.count, MeetingNotes.maxSummaryLength)
        XCTAssertTrue(result?.hasSuffix("…") == true)
    }
}
