import Foundation

/// Text for the S03 banner and the S02 full-screen warning.
public enum AlertText {
    /// S03 title: "Weekly team sync in 5 minutes".
    public static func bannerTitle(for meeting: Meeting) -> String {
        "\(meeting.title) in 5 minutes"
    }

    /// S03 body: "2:00 PM · Conference Room B", or "2:00 PM" with no location.
    public static func bannerBody(for meeting: Meeting, calendar: Calendar = .current) -> String {
        withLocation(TimeText.clock(meeting.start, calendar: calendar), meeting)
    }

    /// S02 countdown: "1:00" ... "0:01", then "Starting now" at or after the start.
    public static func countdown(until start: Date, now: Date) -> String {
        let seconds = Int(start.timeIntervalSince(now).rounded(.up))
        if seconds <= 0 { return "Starting now" }
        let rest = seconds % 60
        return "\(seconds / 60):" + (rest < 10 ? "0\(rest)" : "\(rest)")
    }

    /// S02 time range: "2:00 PM – 2:30 PM".
    public static func timeRange(for meeting: Meeting, calendar: Calendar = .current) -> String {
        TimeText.clock(meeting.start, calendar: calendar) + " – " + TimeText.clock(meeting.end, calendar: calendar)
    }

    /// S02 line under the title: "2:00 PM – 2:30 PM · Conference Room B", or the range alone.
    public static func fullScreenDetail(for meeting: Meeting, calendar: Calendar = .current) -> String {
        withLocation(timeRange(for: meeting, calendar: calendar), meeting)
    }

    /// S02 VoiceOver text, spoken once at open: "Weekly team sync starts in 1 minute. 2:00 PM to 2:30 PM, Conference Room B."
    /// Spelled out because VoiceOver reads "1:00" as a clock time and "·" as a symbol.
    public static func fullScreenAnnouncement(for meeting: Meeting, now: Date, calendar: Calendar = .current) -> String {
        let seconds = Int(meeting.start.timeIntervalSince(now).rounded(.up))
        let when: String
        if seconds <= 0 {
            when = "is starting now"
        } else if seconds >= 60 {
            when = "starts in " + plural(seconds / 60, "minute")
        } else {
            when = "starts in " + plural(seconds, "second")
        }
        var range = TimeText.clock(meeting.start, calendar: calendar) + " to " + TimeText.clock(meeting.end, calendar: calendar)
        if let location = meeting.location?.trimmingCharacters(in: .whitespacesAndNewlines), !location.isEmpty {
            range += ", " + location
        }
        return "\(meeting.title) \(when). \(range)."
    }

    private static func plural(_ n: Int, _ unit: String) -> String {
        "\(n) \(unit)" + (n == 1 ? "" : "s")
    }

    private static func withLocation(_ text: String, _ meeting: Meeting) -> String {
        guard let location = meeting.location?.trimmingCharacters(in: .whitespacesAndNewlines),
              !location.isEmpty else { return text }
        return text + " · " + location
    }
}
