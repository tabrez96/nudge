import Foundation

/// Picks which calendar to read: the saved one if it still exists, else Google's primary
/// (titled with the account's email address), else the first calendar.
public enum CalendarChoice {
    public static func pick(savedID: String?, from calendars: [CalendarInfo]) -> CalendarInfo? {
        if let savedID, let saved = calendars.first(where: { $0.id == savedID }) {
            return saved
        }
        return calendars.first(where: { looksLikeEmail($0.title) }) ?? calendars.first
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
