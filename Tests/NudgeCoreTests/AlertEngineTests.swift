import XCTest
@testable import NudgeCore

final class AlertEngineTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func meeting(_ id: String = "m1", start: Date, allDay: Bool = false, declined: Bool = false) -> Meeting {
        Meeting(id: id, title: "Design review", start: start, end: start.addingTimeInterval(30 * 60),
                location: nil, isAllDay: allDay, isDeclined: declined)
    }

    private func due(_ meetings: [Meeting], at offset: TimeInterval, fired: Set<String> = []) -> [ScheduledAlert] {
        AlertEngine.dueAlerts(meetings: meetings, now: start.addingTimeInterval(offset), firedKeys: fired)
    }

    private func kinds(_ alerts: [ScheduledAlert]) -> [AlertKind] { alerts.map(\.kind) }

    func testMeetingAlertKeyCombinesIdAndStart() {
        XCTAssertEqual(meeting(start: start).alertKey, "m1|1800000000.0")
        XCTAssertNotEqual(meeting(start: start).alertKey, meeting(start: start.addingTimeInterval(600)).alertKey)
    }

    func testNothingBeforeFiveMinuteWindow() {
        XCTAssertEqual(due([meeting(start: start)], at: -301), [])
    }

    func testFiveMinuteFiresAtExactlyTMinus5() {
        XCTAssertEqual(kinds(due([meeting(start: start)], at: -300)), [.fiveMinute])
    }

    func testFiveMinuteStillDueJustBeforeTMinus1() {
        XCTAssertEqual(kinds(due([meeting(start: start)], at: -61)), [.fiveMinute])
    }

    func testOneMinuteFiresAtExactlyTMinus1() {
        let alerts = due([meeting(start: start)], at: -60)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.kind, .oneMinute)
    }

    func testOneMinuteStillDueJustBeforeStart() {
        XCTAssertEqual(kinds(due([meeting(start: start)], at: -1)), [.oneMinute])
    }

    func testNothingAtStart() {
        XCTAssertEqual(due([meeting(start: start)], at: 0), [])
    }

    func testNothingAfterStart() {
        XCTAssertEqual(due([meeting(start: start)], at: 30), [])
    }

    func testLaunchAtTMinus3ReturnsFiveMinute() {
        XCTAssertEqual(kinds(due([meeting(start: start)], at: -180)), [.fiveMinute])
    }

    func testLaunchAtTMinus30sReturnsOnlyOneMinute() {
        let alerts = due([meeting(start: start)], at: -30)
        XCTAssertEqual(alerts.count, 1)
        XCTAssertEqual(alerts.first?.kind, .oneMinute)
    }

    func testFiredFiveMinuteKeyIsNotReturnedAgain() {
        let m = meeting(start: start)
        let fired: Set<String> = [AlertEngine.firedKey(alertKey: m.alertKey, kind: .fiveMinute)]
        XCTAssertEqual(due([m], at: -180, fired: fired), [])
    }

    func testFiredOneMinuteKeyIsNotReturnedAgain() {
        let m = meeting(start: start)
        let fired: Set<String> = [AlertEngine.firedKey(alertKey: m.alertKey, kind: .oneMinute)]
        XCTAssertEqual(due([m], at: -30, fired: fired), [])
    }

    func testOneMinuteStillFiresAfterFiveMinuteFired() {
        let m = meeting(start: start)
        let fired: Set<String> = [AlertEngine.firedKey(alertKey: m.alertKey, kind: .fiveMinute)]
        XCTAssertEqual(kinds(due([m], at: -30, fired: fired)), [.oneMinute])
    }

    func testAllDayMeetingSkipped() {
        let m = meeting(start: start, allDay: true)
        XCTAssertEqual(due([m], at: -180), [])
        XCTAssertEqual(due([m], at: -30), [])
    }

    func testDeclinedMeetingSkipped() {
        let m = meeting(start: start, declined: true)
        XCTAssertEqual(due([m], at: -180), [])
        XCTAssertEqual(due([m], at: -30), [])
    }

    func testRescheduledMeetingAlertsAgain() {
        let original = meeting(start: start)
        let fired = Set(AlertKind.allCases.map { AlertEngine.firedKey(alertKey: original.alertKey, kind: $0) })
        let moved = meeting(start: start.addingTimeInterval(600))
        let alerts = due([moved], at: 600 - 180, fired: fired)
        XCTAssertEqual(alerts, [ScheduledAlert(meeting: moved, kind: .fiveMinute)])
    }

    func testSoonestOneMinuteAlertIsReturnedLast() {
        let a = meeting("a", start: start.addingTimeInterval(30))
        let b = meeting("b", start: start)
        let alerts = due([b, a], at: -20)
        XCTAssertEqual(kinds(alerts), [.oneMinute, .oneMinute])
        XCTAssertEqual(alerts.map(\.meeting.id), ["a", "b"])
    }

    func testSimultaneousMeetingsAreOrderedById() {
        let alerts = due([meeting("b", start: start), meeting("a", start: start)], at: -30)
        XCTAssertEqual(alerts.map(\.meeting.id), ["a", "b"])
        let fives = due([meeting("b", start: start), meeting("a", start: start)], at: -180)
        XCTAssertEqual(fives.map(\.meeting.id), ["a", "b"])
    }

    func testFiveMinuteAlertsComeBeforeOneMinuteAlerts() {
        let soon = meeting("soon", start: start)
        let later = meeting("later", start: start.addingTimeInterval(200))
        let alerts = due([soon, later], at: -30)
        XCTAssertEqual(alerts.first?.kind, .fiveMinute)
        XCTAssertEqual(alerts.last?.kind, .oneMinute)
    }

    func testEmptyMeetingsReturnsNothing() {
        XCTAssertEqual(due([], at: -30), [])
    }

    func testFiredKeyFormat() {
        let alert = ScheduledAlert(meeting: meeting(start: start), kind: .oneMinute)
        XCTAssertEqual(alert.firedKey, "m1|1800000000.0|oneMinute")
    }

    func testPruneDropsKeysOlderThanOneHour() {
        let now = start
        func key(_ offset: TimeInterval) -> String {
            ScheduledAlert(meeting: meeting("k\(Int(offset))", start: now.addingTimeInterval(offset)), kind: .oneMinute).firedKey
        }
        let old = key(-3601), edge = key(-3600), future = key(120)
        let kept = AlertEngine.pruneFiredKeys([old, edge, future], now: now)
        XCTAssertEqual(kept, [edge, future])
    }

    func testPruneHandlesIdsContainingPipe() {
        let now = start
        let fresh = ScheduledAlert(meeting: meeting("a|b", start: now), kind: .fiveMinute).firedKey
        let stale = ScheduledAlert(meeting: meeting("a|b", start: now.addingTimeInterval(-7200)), kind: .fiveMinute).firedKey
        XCTAssertEqual(AlertEngine.pruneFiredKeys([fresh, stale], now: now), [fresh])
    }

    func testPruneDropsMalformedKeys() {
        XCTAssertEqual(AlertEngine.pruneFiredKeys(["garbage", "a|notanumber|oneMinute"], now: start), [])
    }
}
