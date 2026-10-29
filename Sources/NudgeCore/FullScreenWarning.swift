import Foundation

/// What the S02 full-screen warning shows at one moment.
public struct FullScreenContent: Equatable {
    public static let heading = "Starting in"
    public static let buttonTitle = "Got it"
    public static let hint = "Press Return or Esc to dismiss"

    /// "Starting in" above the countdown; nil once the meeting has started, when the countdown reads "Starting now".
    public let heading: String?
    /// "1:00" ... "0:01", then "Starting now".
    public let countdown: String
    public let title: String
    /// "2:00 PM – 2:30 PM · Conference Room B", or the time range alone.
    public let detail: String

    public init(heading: String?, countdown: String, title: String, detail: String) {
        self.heading = heading
        self.countdown = countdown
        self.title = title
        self.detail = detail
    }
}

/// Which meeting S02 is showing. A newer one-minute alert replaces the open one; dismiss clears it. Call from one thread.
public final class FullScreenWarning {
    public private(set) var meeting: Meeting?

    public init() {}

    public var isOpen: Bool { meeting != nil }

    /// Opens (or replaces) the warning for a one-minute alert. Returns false and changes nothing for other kinds.
    @discardableResult
    public func show(_ alert: ScheduledAlert) -> Bool {
        guard alert.kind == .oneMinute else { return false }
        meeting = alert.meeting
        return true
    }

    public func dismiss() { meeting = nil }

    /// Nil when nothing is open.
    public func content(now: Date, calendar: Calendar = .current) -> FullScreenContent? {
        guard let meeting else { return nil }
        let countdown = AlertText.countdown(until: meeting.start, now: now)
        return FullScreenContent(heading: countdown == "Starting now" ? nil : FullScreenContent.heading,
                                 countdown: countdown,
                                 title: meeting.title,
                                 detail: AlertText.fullScreenDetail(for: meeting, calendar: calendar))
    }

    /// Nil when nothing is open.
    public func announcement(now: Date, calendar: Calendar = .current) -> String? {
        meeting.map { AlertText.fullScreenAnnouncement(for: $0, now: now, calendar: calendar) }
    }
}
