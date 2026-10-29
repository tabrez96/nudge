import Foundation

/// What the no-access "Allow calendar access…" row should do for the current permission.
public enum AccessFix: Equatable {
    /// Show the system permission prompt (first run).
    case askSystem
    /// The prompt was already answered "no"; open Privacy & Security → Calendars.
    case openPrivacySettings
    /// Access is fine (no-access is because there's no calendar yet); just re-read.
    case refresh

    public static func forAccess(_ access: CalendarAccess) -> AccessFix {
        switch access {
        case .notDetermined: return .askSystem
        case .denied: return .openPrivacySettings
        case .granted: return .refresh
        }
    }
}

extension MenuIcon {
    /// `.unchanged` (while syncing) keeps `previous`; `previous` is never `.unchanged` in practice, but
    /// if it is, fall back to `.normal`.
    public func resolved(previous: MenuIcon) -> MenuIcon {
        guard self == .unchanged else { return self }
        return previous == .unchanged ? .normal : previous
    }
}

extension StatusDot {
    /// Same rule as `MenuIcon.resolved`; falls back to `.green`.
    public func resolved(previous: StatusDot) -> StatusDot {
        guard self == .unchanged else { return self }
        return previous == .unchanged ? .green : previous
    }
}

/// Text the S01 shell needs besides what `MenuModel` shows.
public enum MenuPresentation {
    public static let maxTitleLength = 34

    /// VoiceOver label for the menu bar button; names the state, never relies on the icon colour.
    public static func statusItemLabel(icon: MenuIcon, status: StatusLine) -> String {
        icon == .problem ? "Nudge, calendar problem. \(status.text)" : "Nudge. \(status.text)"
    }

    /// VoiceOver label for the status line row.
    public static func statusLineLabel(_ status: StatusLine) -> String {
        status.dot == .red ? "Problem: \(status.text)" : status.text
    }

    /// VoiceOver label for a meeting row, e.g. "Weekly team sync, in 4 min" or "1:1 with Dana, at 2:30 PM".
    public static func meetingLabel(_ row: MeetingRow) -> String {
        row.isSoon ? "\(row.title), \(row.detail)" : "\(row.title), at \(row.detail)"
    }

    /// Shortens long meeting titles so the right-aligned time still fits: keeps the first
    /// `max - 1` characters (trailing spaces trimmed) and adds "…". Titles of `max` characters or fewer are unchanged.
    public static func truncated(_ title: String, max: Int = maxTitleLength) -> String {
        guard title.count > max else { return title }
        let head = String(title.prefix(max - 1)).trimmingCharacters(in: .whitespaces)
        return head + "…"
    }
}
