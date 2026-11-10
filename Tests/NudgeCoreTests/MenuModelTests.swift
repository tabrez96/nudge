import XCTest
@testable import NudgeCore

final class MenuModelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000) // 2027-01-15 08:00 UTC
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private let calendars = [
        CalendarInfo(id: "w", title: "Work", sourceTitle: "Google"),
        CalendarInfo(id: "h", title: "Home", sourceTitle: "Google"),
    ]
    private let titles = ["Weekly team sync", "1:1 with Dana", "Design review"]

    private func meeting(_ id: String, title: String? = nil, seconds: TimeInterval,
                         allDay: Bool = false, declined: Bool = false) -> Meeting {
        let start = now.addingTimeInterval(seconds)
        return Meeting(id: id, title: title ?? id, start: start, end: start.addingTimeInterval(1800),
                       location: "Conference Room B", isAllDay: allDay, isDeclined: declined)
    }

    private func three() -> [Meeting] {
        [meeting("a", title: titles[0], seconds: 240),
         meeting("b", title: titles[1], seconds: 6.5 * 3600),
         meeting("c", title: titles[2], seconds: 8 * 3600)]
    }

    private func build(_ status: SyncStatus, _ meetings: [Meeting], selected: String? = "w",
                       notifications: Bool = true, at: Date? = nil) -> MenuModel {
        MenuModel.build(status: status, meetings: meetings, calendars: calendars, selectedID: selected,
                        notificationsAllowed: notifications, now: at ?? now, calendar: utc)
    }

    private let quit = MenuRow.action(.quit, title: "Quit Nudge", keyEquivalent: "q")

    private func controls(selected: String? = "w") -> [MenuRow] {
        [.calendarPicker(title: selected == "h" ? "Calendar: Home" : "Calendar: Work", options: [
            CalendarOption(id: "w", title: "Work", isSelected: selected == "w"),
            CalendarOption(id: "h", title: "Home", isSelected: selected == "h"),
         ]),
         .action(.testAlerts, title: "Test the alerts", keyEquivalent: nil),
         .action(.refresh, title: "Refresh now", keyEquivalent: "r")]
    }

    func testNormalStateRowsAndStatus() {
        let m = build(.synced(at: now), three())
        XCTAssertEqual(m.status, StatusLine(text: "Synced just now · Work", dot: .green))
        XCTAssertEqual(m.icon, .normal)
        XCTAssertEqual(m.rows, [
            .header("Next meetings"),
            .meeting(MeetingRow(title: titles[0], detail: "in 4 min", isSoon: true)),
            .meeting(MeetingRow(title: titles[1], detail: "2:30 PM", isSoon: false)),
            .meeting(MeetingRow(title: titles[2], detail: "4:00 PM", isSoon: false)),
            .separator,
            .calendarPicker(title: "Calendar: Work", options: [
                CalendarOption(id: "w", title: "Work", isSelected: true),
                CalendarOption(id: "h", title: "Home", isSelected: false),
            ]),
            .action(.testAlerts, title: "Test the alerts", keyEquivalent: nil),
            .action(.refresh, title: "Refresh now", keyEquivalent: "r"),
            .separator,
            quit,
        ])
    }

    func testSoonMeetingShowsMinutesAndFlag() {
        let m = build(.synced(at: now), [meeting("a", seconds: 240), meeting("b", seconds: 6.5 * 3600)])
        XCTAssertEqual(m.rows[1], .meeting(MeetingRow(title: "a", detail: "in 4 min", isSoon: true)))
        XCTAssertEqual(m.rows[2], .meeting(MeetingRow(title: "b", detail: "2:30 PM", isSoon: false)))
    }

    func testFiveMinuteBoundary() {
        let row = { (s: TimeInterval) in
            MenuModel.meetingRow(self.meeting("x", seconds: s), now: self.now, calendar: self.utc)
        }
        XCTAssertEqual(row(300), MeetingRow(title: "x", detail: "in 5 min", isSoon: true))
        XCTAssertEqual(row(301), MeetingRow(title: "x", detail: "8:05 AM", isSoon: false))
        XCTAssertEqual(row(30), MeetingRow(title: "x", detail: "in 1 min", isSoon: true))
    }

    func testOnlyLaterTodayMaxThree() {
        let list = [
            meeting("e", seconds: 5 * 3600), meeting("b", seconds: 2 * 3600),
            meeting("d", seconds: 4 * 3600), meeting("a", seconds: 3600),
            meeting("c", seconds: 3 * 3600),
            meeting("started", seconds: -60), meeting("tomorrow", seconds: 20 * 3600),
            meeting("allday", seconds: 600, allDay: true), meeting("declined", seconds: 600, declined: true),
        ]
        let ids = MenuModel.upcomingMeetings(list, now: now, calendar: utc).map(\.id)
        XCTAssertEqual(ids, ["a", "b", "c"])
    }

    func testTomorrowJustAfterMidnightNotListed() {
        let late = now.addingTimeInterval(15 * 3600 + 50 * 60) // 23:50
        let m = build(.synced(at: late), [meeting("n", seconds: 16 * 3600 + 30 * 60)], at: late)
        XCTAssertEqual(m.rows, [.message(MenuModel.emptyText), .separator] + controls() + [.separator, quit])
    }

    func testEmptyState() {
        let m = build(.synced(at: now), [])
        XCTAssertEqual(m.rows, [.message(MenuModel.emptyText), .separator] + controls() + [.separator, quit])
    }

    func testEmptyStateKeepsControlsWhenNotificationsDenied() {
        let m = build(.synced(at: now), [], notifications: false)
        XCTAssertEqual(m.rows,
                       [.warning(MenuModel.notificationsOffText), .separator,
                        .message(MenuModel.emptyText), .separator] + controls() + [.separator, quit])
    }

    func testSyncingEmptyKeepsControls() {
        let m = build(.syncing, [])
        XCTAssertEqual(m.rows, build(.synced(at: now), []).rows)
        XCTAssertEqual(m.status.dot, .unchanged)
    }

    func testEmptyCalendarPickerSwitchesSelection() {
        let empty = build(.synced(at: now), [], selected: "h")
        XCTAssertEqual(empty.status.text, "Synced just now · Home")
        XCTAssertEqual(empty.rows, [.message(MenuModel.emptyText), .separator]
                       + controls(selected: "h") + [.separator, quit])
        let full = build(.synced(at: now), three(), selected: "w")
        XCTAssertEqual(full.rows.first, .header("Next meetings"))
        XCTAssertTrue(full.rows.contains(controls(selected: "w")[0]))
    }

    func testErrorStateWithSavedTime() {
        let saved = now.addingTimeInterval(5 * 3600 + 52 * 60)
        let m = build(.error(.fetchFailed, savedAt: saved), three())
        XCTAssertEqual(m.status.text, "Can't reach your calendar. Alerting from data saved at 1:52 PM.")
        XCTAssertEqual(m.status.dot, .red)
        XCTAssertEqual(m.icon, .problem)
        XCTAssertEqual(m.rows.first, .header("Next meetings (last saved)"))
        XCTAssertTrue(m.rows.contains(.action(.retry, title: "Retry now", keyEquivalent: "r")))
        XCTAssertTrue(m.rows.contains(quit))
        XCTAssertFalse(m.rows.contains(.action(.refresh, title: "Refresh now", keyEquivalent: "r")))
        XCTAssertFalse(m.rows.contains { if case .calendarPicker = $0 { return true } else { return false } })
    }

    func testErrorStateWithoutSavedTimeAndNoMeetings() {
        let m = build(.error(.fetchFailed, savedAt: nil), [])
        XCTAssertEqual(m.status.text, "Can't reach your calendar. Nothing saved to alert from yet.")
        XCTAssertEqual(m.rows, [.action(.retry, title: "Retry now", keyEquivalent: "r"), .separator, quit])
    }

    func testNoAccessState() {
        let m = build(.noAccess, three(), notifications: false)
        XCTAssertEqual(m.status, StatusLine(text: "Nudge can't see your calendar yet.", dot: .red))
        XCTAssertEqual(m.icon, .problem)
        XCTAssertEqual(m.rows, [
            .action(.allowCalendarAccess, title: "Allow calendar access…", keyEquivalent: nil),
            .action(.openInternetAccounts, title: "Add Google account in Internet Accounts…", keyEquivalent: nil),
            .separator, quit,
        ])
    }

    func testSyncingKeepsDotIconAndList() {
        let m = build(.syncing, three())
        XCTAssertEqual(m.status, StatusLine(text: "Syncing…", dot: .unchanged))
        XCTAssertEqual(m.icon, .unchanged)
        XCTAssertEqual(m.rows.first, .header("Next meetings"))
        XCTAssertEqual(m.rows.count, build(.synced(at: now), three()).rows.count)
    }

    func testNotificationsDeniedAddsWarningFirst() {
        let m = build(.synced(at: now), three(), notifications: false)
        XCTAssertEqual(Array(m.rows.prefix(3)),
                       [.warning(MenuModel.notificationsOffText), .separator, .header("Next meetings")])
        XCTAssertEqual(m.icon, .normal)
    }

    func testUnknownSelectedCalendar() {
        for id in [nil, "zzz"] as [String?] {
            let m = build(.synced(at: now), three(), selected: id)
            XCTAssertEqual(m.status.text, "Synced just now")
            guard case .calendarPicker(let title, let options) = m.rows[5] else {
                return XCTFail("expected picker")
            }
            XCTAssertEqual(title, "Calendar")
            XCTAssertTrue(options.allSatisfy { !$0.isSelected })
        }
    }

    func testNoCopyHasExclamationMarks() {
        let saved = now.addingTimeInterval(3600)
        let statuses: [SyncStatus] = [.synced(at: now), .syncing, .error(.fetchFailed, savedAt: saved),
                                      .error(.fetchFailed, savedAt: nil), .noAccess]
        var strings: [String] = []
        for status in statuses {
            for meetings in [three(), []] {
                for allowed in [true, false] {
                    let m = build(status, meetings, notifications: allowed)
                    strings.append(m.status.text)
                    for row in m.rows {
                        switch row {
                        case .separator: break
                        case .header(let s), .message(let s), .warning(let s): strings.append(s)
                        case .meeting(let r): strings += [r.title, r.detail]
                        case .calendarPicker(let t, let o): strings += [t] + o.map(\.title)
                        case .action(_, let t, _): strings.append(t)
                        }
                    }
                }
            }
        }
        XCTAssertFalse(strings.isEmpty)
        for s in strings where !titles.contains(s) { XCTAssertFalse(s.contains("!"), s) }
    }

    // MARK: Now section

    private func running(_ id: String, start: TimeInterval = -600, end: TimeInterval = 1800,
                         allDay: Bool = false, declined: Bool = false) -> Meeting {
        Meeting(id: id, title: id, start: now.addingTimeInterval(start), end: now.addingTimeInterval(end),
                isAllDay: allDay, isDeclined: declined)
    }

    private func nowRow(_ id: String, _ detail: String = "until 8:30 AM") -> MenuRow {
        .meeting(MeetingRow(title: id, detail: detail, isSoon: false, isNow: true))
    }

    func testRunningMeetingShownUnderNowAboveNextMeetings() {
        let m = build(.synced(at: now), [running("r"), meeting("u", seconds: 6.5 * 3600)])
        XCTAssertEqual(m.rows, [
            .header("Now"),
            nowRow("r"),
            .header("Next meetings"),
            .meeting(MeetingRow(title: "u", detail: "2:30 PM", isSoon: false)),
            .separator,
        ] + controls() + [.separator, quit])
    }

    func testRunningMeetingOnlyHidesEmptyText() {
        let m = build(.synced(at: now), [running("r")])
        XCTAssertEqual(Array(m.rows.prefix(2)), [.header("Now"), nowRow("r")])
        XCTAssertFalse(m.rows.contains(.message(MenuModel.emptyText)))
        XCTAssertFalse(m.rows.contains(.header("Next meetings")))
    }

    func testEmptyTextOnlyWhenNothingRunningOrUpcoming() {
        let m = build(.synced(at: now), [running("done", start: -1800, end: 0)])
        XCTAssertEqual(m.rows.first, .message(MenuModel.emptyText))
    }

    func testRunningBoundaries() {
        let all = [
            running("starts-now", start: 0),
            running("ends-now", start: -600, end: 0),
            running("zero", start: 0, end: 0),
            running("allday", allDay: true),
            running("declined", declined: true),
        ]
        XCTAssertEqual(MenuModel.runningMeetings(all, now: now).map(\.id), ["starts-now"])
    }

    func testRunningMeetingNeverSoon() {
        let row = MenuModel.nowRow(running("r", start: -30), calendar: utc)
        XCTAssertFalse(row.isSoon)
        XCTAssertTrue(row.isNow)
        XCTAssertTrue(row.detail.hasPrefix("until "))
    }

    func testOverlappingRunningMeetingsSortedAndCapped() {
        let m = build(.synced(at: now), [running("d", start: -100), running("b", start: -300),
                                         running("a", start: -400), running("c", start: -200)])
        XCTAssertEqual(Array(m.rows.prefix(4)), [.header("Now"), nowRow("a"), nowRow("b"), nowRow("c")])
        XCTAssertEqual(m.rows[4], .separator)
    }

    func testRunningMeetingFromYesterdayStillShown() {
        let m = build(.synced(at: now), [running("late", start: -9 * 3600, end: 600)])
        XCTAssertEqual(Array(m.rows.prefix(2)), [.header("Now"), nowRow("late", "until 8:10 AM")])
    }

    func testErrorStateShowsNowAboveLastSaved() {
        let m = build(.error(.fetchFailed, savedAt: now), [running("r"), meeting("u", seconds: 6.5 * 3600)])
        XCTAssertEqual(Array(m.rows.prefix(4)), [
            .header("Now"),
            nowRow("r"),
            .header("Next meetings (last saved)"),
            .meeting(MeetingRow(title: "u", detail: "2:30 PM", isSoon: false)),
        ])
    }
}
