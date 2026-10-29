import XCTest
@testable import NudgeCore

final class FullScreenWarningTests: XCTestCase {
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    // 2027-01-15 08:00 UTC
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private var start: Date { base.addingTimeInterval(6 * 3600) }

    private func meeting(id: String = "a", title: String = "Weekly team sync",
                         location: String? = "Conference Room B") -> Meeting {
        Meeting(id: id, title: title, start: start, end: start.addingTimeInterval(1800), location: location)
    }

    private func oneMinute(_ m: Meeting) -> ScheduledAlert { ScheduledAlert(meeting: m, kind: .oneMinute) }

    func testStartsClosed() {
        let w = FullScreenWarning()
        XCTAssertFalse(w.isOpen)
        XCTAssertNil(w.content(now: start, calendar: utc))
        XCTAssertNil(w.announcement(now: start, calendar: utc))
    }

    func testIgnoresFiveMinuteAlerts() {
        let w = FullScreenWarning()
        XCTAssertFalse(w.show(ScheduledAlert(meeting: meeting(), kind: .fiveMinute)))
        XCTAssertFalse(w.isOpen)
    }

    func testOneMinuteAlertOpensWithContent() {
        let w = FullScreenWarning()
        XCTAssertTrue(w.show(oneMinute(meeting())))
        XCTAssertEqual(w.content(now: start.addingTimeInterval(-60), calendar: utc),
                       FullScreenContent(heading: "Starting in", countdown: "1:00", title: "Weekly team sync",
                                         detail: "2:00 PM – 2:30 PM · Conference Room B"))
    }

    func testCountsDownToStartingNowAndStays() {
        let w = FullScreenWarning()
        w.show(oneMinute(meeting()))
        let last = w.content(now: start.addingTimeInterval(-1), calendar: utc)
        XCTAssertEqual(last?.countdown, "0:01")
        XCTAssertEqual(last?.heading, "Starting in")
        for offset in [0.0, 30] {
            let c = w.content(now: start.addingTimeInterval(offset), calendar: utc)
            XCTAssertEqual(c?.countdown, "Starting now")
            XCTAssertNil(c?.heading)
            XCTAssertTrue(w.isOpen)
        }
    }

    func testNoLocationShowsTimeRangeOnly() {
        let w = FullScreenWarning()
        w.show(oneMinute(meeting(location: nil)))
        XCTAssertEqual(w.content(now: start.addingTimeInterval(-60), calendar: utc)?.detail, "2:00 PM – 2:30 PM")
    }

    func testNewerAlertReplacesOpenOne() {
        let w = FullScreenWarning()
        let b = meeting(id: "b", title: "Design review")
        w.show(oneMinute(meeting()))
        w.show(oneMinute(b))
        XCTAssertEqual(w.meeting, b)
        XCTAssertEqual(w.content(now: start.addingTimeInterval(-30), calendar: utc)?.title, "Design review")
    }

    func testFiveMinuteAlertDoesNotReplaceOpenOne() {
        let w = FullScreenWarning()
        let a = meeting()
        w.show(oneMinute(a))
        w.show(ScheduledAlert(meeting: meeting(id: "b", title: "Other"), kind: .fiveMinute))
        XCTAssertEqual(w.meeting, a)
    }

    func testDismissClosesAndCanReopen() {
        let w = FullScreenWarning()
        w.show(oneMinute(meeting()))
        w.dismiss()
        XCTAssertFalse(w.isOpen)
        XCTAssertNil(w.content(now: start, calendar: utc))
        w.show(oneMinute(meeting()))
        XCTAssertTrue(w.isOpen)
    }

    func testAnnouncementWhenOpen() {
        let w = FullScreenWarning()
        w.show(oneMinute(meeting()))
        XCTAssertEqual(w.announcement(now: start.addingTimeInterval(-60), calendar: utc),
                       "Weekly team sync starts in 1 minute. 2:00 PM to 2:30 PM, Conference Room B.")
    }
}
