import XCTest
@testable import NudgeCore

final class JoinLinkTests: XCTestCase {
    private let meet = "https://meet.google.com/abc-defg-hij"

    func testURLFieldWins() {
        let url = URL(string: "https://zoom.us/j/1")!
        XCTAssertEqual(JoinLink.find(url: url, location: nil, notes: "Join \(meet)"), url)
    }

    func testNonWebURLFieldIgnored() {
        let mail = URL(string: "mailto:a@example.com")
        XCTAssertEqual(JoinLink.find(url: mail, location: meet, notes: nil), URL(string: meet))
    }

    func testGoogleMeetInLocation() {
        XCTAssertEqual(JoinLink.find(url: nil, location: meet, notes: nil), URL(string: meet))
    }

    func testZoomInNotes() {
        let zoom = "https://us02web.zoom.us/j/123?pwd=abc"
        XCTAssertEqual(JoinLink.find(url: nil, location: nil, notes: "Join Zoom Meeting\n\(zoom)"), URL(string: zoom))
    }

    func testTeamsInHTMLNotes() {
        let notes = "<a href=\"https://teams.microsoft.com/l/meetup-join/x?a=1&amp;b=2\">Join</a>"
        XCTAssertEqual(JoinLink.find(url: nil, location: nil, notes: notes),
                       URL(string: "https://teams.microsoft.com/l/meetup-join/x?a=1&b=2"))
    }

    func testConferencingPreferredOverEarlierPlainLink() {
        let notes = "Doc: https://docs.example.com/x then https://meet.google.com/abc"
        XCTAssertEqual(JoinLink.find(url: nil, location: nil, notes: notes), URL(string: "https://meet.google.com/abc"))
    }

    func testPlainHttpsLinkFallback() {
        XCTAssertEqual(JoinLink.find(url: nil, location: nil, notes: "Agenda https://example.com/agenda."),
                       URL(string: "https://example.com/agenda"))
    }

    func testHttpLinkInTextIgnored() {
        XCTAssertNil(JoinLink.find(url: nil, location: nil, notes: "see http://example.com"))
    }

    func testNoLink() {
        XCTAssertNil(JoinLink.find(url: nil, location: nil, notes: nil))
        XCTAssertNil(JoinLink.find(url: nil, location: "Room B", notes: "Bring snacks"))
    }

    func testMeetingJoinLinkUsesAllFields() {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let m = Meeting(id: "a", title: "Sync", start: start, end: start.addingTimeInterval(1800),
                        location: "Room B", url: nil, notes: "Link: \(meet)")
        XCTAssertEqual(m.joinLink, JoinLink.find(url: nil, location: "Room B", notes: "Link: \(meet)"))
        XCTAssertEqual(m.joinLink, URL(string: meet))
    }
}
