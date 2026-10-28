import Foundation

/// Whether the user has let Nudge read their calendars.
public enum CalendarAccess: Equatable {
    case granted
    case notDetermined
    case denied
}

/// One calendar the user could pick in S01's Calendar submenu.
public struct CalendarInfo: Equatable, Hashable {
    public let id: String
    public let title: String
    public let sourceTitle: String

    public init(id: String, title: String, sourceTitle: String) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
    }
}

/// Why reading meetings failed.
public enum CalendarSourceError: Error, Equatable {
    case accessDenied
    case calendarNotFound
    case fetchFailed
}

/// Read-only view of the user's calendars. The system calendar in the app; a fake in tests.
public protocol CalendarSource {
    func authorization() -> CalendarAccess
    func calendars() -> [CalendarInfo]
    /// Meetings that overlap `from..<to` in the given calendar. Throws `CalendarSourceError`.
    func meetings(calendarID: String, from: Date, to: Date) throws -> [Meeting]
}
