import Foundation

/// Colour of the dot in S01's status line. `.unchanged` keeps whatever is showing (used while syncing).
public enum StatusDot: Equatable { case green, red, unchanged }

/// Menu bar icon: plain template bell, or the same bell with a red dot while a calendar problem exists.
public enum MenuIcon: Equatable { case normal, problem, unchanged }

/// What a clickable S01 row does; the shell maps each to an action.
public enum MenuAction: Equatable {
    case testAlerts, refresh, retry, allowCalendarAccess, openInternetAccounts, quit
}

public struct StatusLine: Equatable {
    public let text: String
    public let dot: StatusDot

    public init(text: String, dot: StatusDot) {
        self.text = text
        self.dot = dot
    }
}

public struct MeetingRow: Equatable {
    public let title: String
    /// "in 4 min" when soon, "until 2:30 PM" when running now, else the start time ("2:30 PM").
    public let detail: String
    /// True when the meeting starts within 5 minutes; S01 draws `detail` in bold amber.
    public let isSoon: Bool
    /// True when the meeting is running now; listed under the "Now" header.
    public let isNow: Bool
    /// Cleaned notes shown under the title (two lines max); nil shows nothing.
    public let summary: String?
    /// Link the row opens; nil makes the row non-clickable with no pill.
    public let joinURL: URL?

    public init(title: String, detail: String, isSoon: Bool, isNow: Bool = false,
                summary: String? = nil, joinURL: URL? = nil) {
        self.title = title
        self.detail = detail
        self.isSoon = isSoon
        self.isNow = isNow
        self.summary = summary
        self.joinURL = joinURL
    }
}

public struct CalendarOption: Equatable {
    public let id: String
    public let title: String
    public let isSelected: Bool

    public init(id: String, title: String, isSelected: Bool) {
        self.id = id
        self.title = title
        self.isSelected = isSelected
    }
}

public enum MenuRow: Equatable {
    case separator
    /// Section header text, mixed case; the shell renders it as a menu section header.
    case header(String)
    case meeting(MeetingRow)
    /// Muted, non-clickable text (the empty state).
    case message(String)
    /// Non-clickable warning text (notifications denied).
    case warning(String)
    /// "Calendar: Work ▸" submenu.
    case calendarPicker(title: String, options: [CalendarOption])
    /// `keyEquivalent` is the lowercase key used with ⌘, e.g. "r", "q"; nil for none.
    case action(MenuAction, title: String, keyEquivalent: String?)
}

/// Everything S01 shows. `rows` are the rows below the status line, in order, separators included.
public struct MenuModel: Equatable {
    public let status: StatusLine
    public let icon: MenuIcon
    public let rows: [MenuRow]

    public init(status: StatusLine, icon: MenuIcon, rows: [MenuRow]) {
        self.status = status
        self.icon = icon
        self.rows = rows
    }
}

extension MenuModel {
    public static let syncingText = "Syncing…"
    public static let noAccessText = "Nudge can't see your calendar yet."
    public static let nowHeader = "Now"
    public static let nextMeetingsHeader = "Next meetings"
    public static let lastSavedHeader = "Next meetings (last saved)"
    public static let emptyText = "No more meetings today. Enjoy the quiet."
    public static let notificationsOffText = "Notifications are off for Nudge. Sound still plays."

    public static func build(status: SyncStatus, meetings: [Meeting], calendars: [CalendarInfo],
                             selectedID: String?, notificationsAllowed: Bool, now: Date,
                             calendar: Calendar = .current) -> MenuModel {
        let warningGroup: [MenuRow] = notificationsAllowed ? [] : [.warning(notificationsOffText)]
        let meetingRows: [MenuRow] = upcomingMeetings(meetings, now: now, calendar: calendar)
            .map { .meeting(meetingRow($0, now: now, calendar: calendar)) }
        let nowRows: [MenuRow] = runningMeetings(meetings, now: now).map { .meeting(nowRow($0, calendar: calendar)) }
        let quitGroup: [MenuRow] = [.action(.quit, title: "Quit Nudge", keyEquivalent: "q")]

        switch status {
        case .synced, .syncing:
            let selected = calendars.first { $0.id == selectedID }
            let line: StatusLine
            let icon: MenuIcon
            if case .syncing = status {
                line = StatusLine(text: syncingText, dot: .unchanged)
                icon = .unchanged
            } else {
                let text = selected.map { "Synced just now · \($0.title)" } ?? "Synced just now"
                line = StatusLine(text: text, dot: .green)
                icon = .normal
            }
            let options = calendars.map {
                CalendarOption(id: $0.id, title: $0.title, isSelected: $0.id == selected?.id)
            }
            let controls: [MenuRow] = [
                .calendarPicker(title: selected.map { "Calendar: \($0.title)" } ?? "Calendar", options: options),
                .action(.testAlerts, title: "Test the alerts", keyEquivalent: nil),
                .action(.refresh, title: "Refresh now", keyEquivalent: "r"),
            ]
            let group = meetingGroup(now: nowRows, next: meetingRows, nextHeader: nextMeetingsHeader)
            return MenuModel(status: line, icon: icon,
                             rows: joined([warningGroup, group.isEmpty ? [.message(emptyText)] : group,
                                           controls, quitGroup]))
        case .error(_, let savedAt):
            let text = savedAt.map {
                "Can't reach your calendar. Alerting from data saved at \(TimeText.clock($0, calendar: calendar))."
            } ?? "Can't reach your calendar. Nothing saved to alert from yet."
            let list = meetingGroup(now: nowRows, next: meetingRows, nextHeader: lastSavedHeader)
            let retry: [MenuRow] = [.action(.retry, title: "Retry now", keyEquivalent: "r")]
            return MenuModel(status: StatusLine(text: text, dot: .red), icon: .problem,
                             rows: joined([warningGroup, list, retry, quitGroup]))
        case .noAccess:
            let fix: [MenuRow] = [
                .action(.allowCalendarAccess, title: "Allow calendar access…", keyEquivalent: nil),
                .action(.openInternetAccounts, title: "Add Google account in Internet Accounts…",
                        keyEquivalent: nil),
            ]
            return MenuModel(status: StatusLine(text: noAccessText, dot: .red), icon: .problem,
                             rows: joined([fix, quitGroup]))
        }
    }

    static func joined(_ groups: [[MenuRow]]) -> [MenuRow] {
        var rows: [MenuRow] = []
        for group in groups where !group.isEmpty {
            if !rows.isEmpty { rows.append(.separator) }
            rows += group
        }
        return rows
    }

    /// "Now" section (if any) followed by the next-meetings section (if any), in one group with no separator.
    static func meetingGroup(now nowRows: [MenuRow], next nextRows: [MenuRow], nextHeader: String) -> [MenuRow] {
        let nowSection: [MenuRow] = nowRows.isEmpty ? [] : [.header(nowHeader)] + nowRows
        let nextSection: [MenuRow] = nextRows.isEmpty ? [] : [.header(nextHeader)] + nextRows
        return nowSection + nextSection
    }

    /// Meetings in progress at `now` (start <= now < end), earliest start first, at most 3.
    static func runningMeetings(_ meetings: [Meeting], now: Date) -> [Meeting] {
        let running = meetings.filter { !$0.isAllDay && !$0.isDeclined && $0.start <= now && now < $0.end }
        let sorted = running.sorted { ($0.start, $0.id) < ($1.start, $1.id) }
        return Array(sorted.prefix(3))
    }

    static func nowRow(_ meeting: Meeting, calendar: Calendar) -> MeetingRow {
        MeetingRow(title: meeting.title, detail: "until \(TimeText.clock(meeting.end, calendar: calendar))",
                   isSoon: false, isNow: true, summary: meeting.summary, joinURL: meeting.joinLink)
    }

    static func upcomingMeetings(_ meetings: [Meeting], now: Date, calendar: Calendar) -> [Meeting] {
        let later = meetings.filter {
            !$0.isAllDay && !$0.isDeclined && $0.start > now && calendar.isDate($0.start, inSameDayAs: now)
        }
        let sorted = later.sorted { ($0.start, $0.id) < ($1.start, $1.id) }
        return Array(sorted.prefix(3))
    }

    static func meetingRow(_ meeting: Meeting, now: Date, calendar: Calendar) -> MeetingRow {
        let untilStart = meeting.start.timeIntervalSince(now)
        if untilStart <= AlertEngine.fiveMinuteLead {
            let n = Int((untilStart / 60).rounded(.up))
            return MeetingRow(title: meeting.title, detail: "in \(n) min", isSoon: true,
                              summary: meeting.summary, joinURL: meeting.joinLink)
        }
        return MeetingRow(title: meeting.title, detail: TimeText.clock(meeting.start, calendar: calendar),
                          isSoon: false, summary: meeting.summary, joinURL: meeting.joinLink)
    }
}
