import Foundation

/// Which alert to show: the S03 banner at T-5 min or the S02 full-screen warning at T-1 min.
public enum AlertKind: String, Equatable, Hashable, CaseIterable {
    case fiveMinute
    case oneMinute
}

/// An alert that is due now for one meeting.
public struct ScheduledAlert: Equatable, Hashable {
    public let meeting: Meeting
    public let kind: AlertKind

    public init(meeting: Meeting, kind: AlertKind) {
        self.meeting = meeting
        self.kind = kind
    }

    /// Key to insert into `firedKeys` once this alert has been shown.
    public var firedKey: String { AlertEngine.firedKey(alertKey: meeting.alertKey, kind: kind) }
}

/// Decides which alerts are due. Pure: no clock, no state.
public enum AlertEngine {
    public static let fiveMinuteLead: TimeInterval = 5 * 60
    public static let oneMinuteLead: TimeInterval = 60
    public static let firedKeyRetention: TimeInterval = 60 * 60

    public static func firedKey(alertKey: String, kind: AlertKind) -> String {
        "\(alertKey)|\(kind.rawValue)"
    }

    /// Alerts due at `now`: five-minute ones first, then one-minute ones with the soonest-starting last.
    public static func dueAlerts(meetings: [Meeting], now: Date, firedKeys: Set<String>) -> [ScheduledAlert] {
        var fives: [Meeting] = []
        var ones: [Meeting] = []
        for meeting in meetings where !meeting.isAllDay && !meeting.isDeclined {
            let untilStart = meeting.start.timeIntervalSince(now)
            let kind: AlertKind
            if untilStart > oneMinuteLead && untilStart <= fiveMinuteLead {
                kind = .fiveMinute
            } else if untilStart > 0 && untilStart <= oneMinuteLead {
                kind = .oneMinute
            } else {
                continue
            }
            if firedKeys.contains(firedKey(alertKey: meeting.alertKey, kind: kind)) { continue }
            if kind == .fiveMinute { fives.append(meeting) } else { ones.append(meeting) }
        }
        fives.sort { ($0.start, $0.id) < ($1.start, $1.id) }
        ones.sort { $0.start != $1.start ? $0.start > $1.start : $0.id < $1.id }
        return fives.map { ScheduledAlert(meeting: $0, kind: .fiveMinute) }
            + ones.map { ScheduledAlert(meeting: $0, kind: .oneMinute) }
    }

    /// Drops fired keys whose meeting started more than an hour ago, and keys that don't parse.
    public static func pruneFiredKeys(_ firedKeys: Set<String>, now: Date) -> Set<String> {
        let cutoff = now.addingTimeInterval(-firedKeyRetention)
        return firedKeys.filter { key in
            guard let start = startDate(ofFiredKey: key) else { return false }
            return start >= cutoff
        }
    }

    private static func startDate(ofFiredKey key: String) -> Date? {
        let parts = key.split(separator: "|", omittingEmptySubsequences: false)
        guard parts.count >= 3, let seconds = Double(parts[parts.count - 2]) else { return nil }
        return Date(timeIntervalSince1970: seconds)
    }
}
