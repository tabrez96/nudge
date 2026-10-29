import XCTest
@testable import NudgeCore

final class NotificationAccessTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testNotDeterminedIsNotDetermined() {
        XCTAssertEqual(NotificationAccess.from(status: .notDetermined, alertsEnabled: true), .notDetermined)
    }

    func testDeniedIsDenied() {
        XCTAssertEqual(NotificationAccess.from(status: .denied, alertsEnabled: true), .denied)
    }

    func testAuthorizedWithAlertsIsAllowed() {
        XCTAssertEqual(NotificationAccess.from(status: .authorized, alertsEnabled: true), .allowed)
        XCTAssertEqual(NotificationAccess.from(status: .provisional, alertsEnabled: true), .allowed)
    }

    func testAuthorizedWithAlertStyleNoneIsDenied() {
        XCTAssertEqual(NotificationAccess.from(status: .authorized, alertsEnabled: false), .denied)
        XCTAssertEqual(NotificationAccess.from(status: .provisional, alertsEnabled: false), .denied)
    }

    func testOnlyDeniedHidesNotifications() {
        XCTAssertTrue(NotificationAccess.allowed.notificationsAllowed)
        XCTAssertTrue(NotificationAccess.notDetermined.notificationsAllowed)
        XCTAssertFalse(NotificationAccess.denied.notificationsAllowed)
    }

    func testDeniedAccessShowsS01Warning() {
        let calendars = [CalendarInfo(id: "w", title: "Work", sourceTitle: "Google")]
        let start = now.addingTimeInterval(3600)
        let meetings = [Meeting(id: "a", title: "Weekly team sync", start: start,
                                end: start.addingTimeInterval(1800), location: nil,
                                isAllDay: false, isDeclined: false)]
        func rows(_ access: NotificationAccess) -> [MenuRow] {
            MenuModel.build(status: .synced(at: now), meetings: meetings, calendars: calendars,
                            selectedID: "w", notificationsAllowed: access.notificationsAllowed, now: now).rows
        }
        XCTAssertTrue(rows(.denied).contains(.warning(MenuModel.notificationsOffText)))
        XCTAssertFalse(rows(.allowed).contains(.warning(MenuModel.notificationsOffText)))
        XCTAssertFalse(rows(.notDetermined).contains(.warning(MenuModel.notificationsOffText)))
    }
}
