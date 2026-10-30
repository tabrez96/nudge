import Foundation

/// What a refresh should read.
public enum CalendarResolution: Equatable {
    case use(CalendarInfo)
    /// The calendar read last time is gone (e.g. its account was turned off in Internet Accounts).
    case missing(CalendarInfo)
    /// No calendars, and nothing was read before.
    case none
}

/// Picks which calendar to read: the saved one if it still exists, else Google's primary
/// (titled with the account's email address), else the first calendar.
public enum CalendarChoice {
    public static func pick(savedID: String?, from calendars: [CalendarInfo]) -> CalendarInfo? {
        if let savedID, let saved = calendars.first(where: { $0.id == savedID }) {
            return saved
        }
        return calendars.first(where: { looksLikeEmail($0.title) }) ?? calendars.first
    }

    /// The user's saved pick if present; else the calendar read last time, matched by ID, or by title and
    /// account when the account was turned back on and its calendar got a new ID (only if exactly one
    /// calendar matches); else `.missing`.
    /// With nothing read before, falls back to `pick`.
    public static func resolve(savedID: String?, previous: CalendarInfo?,
                               from calendars: [CalendarInfo]) -> CalendarResolution {
        if let savedID, let saved = calendars.first(where: { $0.id == savedID }) { return .use(saved) }
        if let previous {
            if let same = calendars.first(where: { $0.id == previous.id }) { return .use(same) }
            let readded = calendars.filter {
                $0.title == previous.title && $0.sourceTitle == previous.sourceTitle
            }
            if readded.count == 1, let only = readded.first { return .use(only) }
            return .missing(previous)
        }
        return pick(savedID: nil, from: calendars).map { .use($0) } ?? .none
    }

    /// True for `name@domain.tld` with no spaces; deliberately loose.
    public static func looksLikeEmail(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains(where: { $0.isWhitespace }) { return false }
        let parts = trimmed.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return false }
        let domain = parts[1]
        guard let dot = domain.firstIndex(of: ".") else { return false }
        return dot != domain.startIndex && domain.last != "."
    }
}
