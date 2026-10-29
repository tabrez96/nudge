import XCTest
@testable import NudgeCore

final class MenuPresentationTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let calendars = [CalendarInfo(id: "w", title: "Work", sourceTitle: "Google")]

    func testAccessFixForEachAccess() {
        XCTAssertEqual(AccessFix.forAccess(.notDetermined), .askSystem)
        XCTAssertEqual(AccessFix.forAccess(.denied), .openPrivacySettings)
        XCTAssertEqual(AccessFix.forAccess(.granted), .refresh)
    }

    func testIconUnchangedKeepsPrevious() {
        XCTAssertEqual(MenuIcon.unchanged.resolved(previous: .problem), .problem)
        XCTAssertEqual(MenuIcon.unchanged.resolved(previous: .normal), .normal)
    }

    func testIconConcreteValueWins() {
        XCTAssertEqual(MenuIcon.normal.resolved(previous: .problem), .normal)
        XCTAssertEqual(MenuIcon.problem.resolved(previous: .normal), .problem)
    }

    func testIconUnchangedWithNoPreviousFallsBackToNormal() {
        XCTAssertEqual(MenuIcon.unchanged.resolved(previous: .unchanged), .normal)
    }

    func testDotUnchangedKeepsPrevious() {
        XCTAssertEqual(StatusDot.unchanged.resolved(previous: .red), .red)
        XCTAssertEqual(StatusDot.green.resolved(previous: .red), .green)
        XCTAssertEqual(StatusDot.unchanged.resolved(previous: .unchanged), .green)
    }

    func testStatusItemLabelNamesProblem() {
        let status = StatusLine(text: "Nudge can't see your calendar yet.", dot: .red)
        XCTAssertEqual(MenuPresentation.statusItemLabel(icon: .problem, status: status),
                       "Nudge, calendar problem. Nudge can't see your calendar yet.")
    }

    func testStatusItemLabelNormal() {
        let status = StatusLine(text: "Synced just now · Work", dot: .green)
        XCTAssertEqual(MenuPresentation.statusItemLabel(icon: .normal, status: status),
                       "Nudge. Synced just now · Work")
    }

    func testStatusLineLabelPrefixesProblem() {
        XCTAssertEqual(MenuPresentation.statusLineLabel(StatusLine(text: "Oops", dot: .red)), "Problem: Oops")
        XCTAssertEqual(MenuPresentation.statusLineLabel(StatusLine(text: "Fine", dot: .green)), "Fine")
        XCTAssertEqual(MenuPresentation.statusLineLabel(StatusLine(text: "Syncing…", dot: .unchanged)), "Syncing…")
    }

    func testMeetingLabelSoonAndLater() {
        XCTAssertEqual(MenuPresentation.meetingLabel(
            MeetingRow(title: "Weekly team sync", detail: "in 4 min", isSoon: true)),
            "Weekly team sync, in 4 min")
        XCTAssertEqual(MenuPresentation.meetingLabel(
            MeetingRow(title: "1:1 with Dana", detail: "2:30 PM", isSoon: false)),
            "1:1 with Dana, at 2:30 PM")
    }

    func testTruncatedLeavesShortTitles() {
        let exact = String(repeating: "a", count: 34)
        XCTAssertEqual(MenuPresentation.truncated(exact), exact)
        XCTAssertEqual(MenuPresentation.truncated("Design review"), "Design review")
    }

    func testTruncatedShortensLongTitles() {
        let long = MenuPresentation.truncated(String(repeating: "a", count: 50))
        XCTAssertEqual(long.count, 34)
        XCTAssertTrue(long.hasSuffix("…"))
        // 33rd character is a space: it must not be left before the "…".
        let spaced = String(repeating: "a", count: 32) + " " + String(repeating: "b", count: 10)
        let result = MenuPresentation.truncated(spaced)
        XCTAssertEqual(result, String(repeating: "a", count: 32) + "…")
    }

    func testMenuModelStatesFeedPresentation() {
        func model(_ status: SyncStatus) -> MenuModel {
            MenuModel.build(status: status, meetings: [], calendars: calendars, selectedID: "w",
                            notificationsAllowed: true, now: now, calendar: utc)
        }
        for status in [SyncStatus.error(.fetchFailed, savedAt: nil), .noAccess] {
            let m = model(status)
            XCTAssertTrue(MenuPresentation.statusItemLabel(icon: m.icon, status: m.status)
                .hasPrefix("Nudge, calendar problem."))
        }
        let ok = model(.synced(at: now))
        XCTAssertTrue(MenuPresentation.statusItemLabel(icon: ok.icon, status: ok.status)
            .hasPrefix("Nudge. Synced just now"))
    }
}
