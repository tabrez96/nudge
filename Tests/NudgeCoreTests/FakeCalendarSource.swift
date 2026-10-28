import Foundation
@testable import NudgeCore

final class FakeCalendarSource: CalendarSource {
    var access: CalendarAccess = .granted
    var calendarList: [CalendarInfo] = [CalendarInfo(id: "cal1", title: "alex@example.com", sourceTitle: "Google")]
    var result: Result<[Meeting], Error> = .success([])
    var onFetch: (() -> Void)?
    private(set) var fetches: [(calendarID: String, from: Date, to: Date)] = []

    func authorization() -> CalendarAccess { access }
    func calendars() -> [CalendarInfo] { calendarList }
    func meetings(calendarID: String, from: Date, to: Date) throws -> [Meeting] {
        fetches.append((calendarID, from, to))
        onFetch?()
        return try result.get()
    }
}
