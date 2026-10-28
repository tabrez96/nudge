import XCTest
@testable import NudgeCore

final class AlertTickerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func meeting(_ id: String = "m1", startingIn seconds: TimeInterval) -> Meeting {
        let start = now.addingTimeInterval(seconds)
        return Meeting(id: id, title: "Standup", start: start, end: start.addingTimeInterval(1800))
    }

    func testReturnsDueAlertAndMarksItFired() {
        let ticker = AlertTicker()
        let m = meeting(startingIn: 4 * 60)
        let due = ticker.tick(meetings: [m], now: now)
        XCTAssertEqual(due.map(\.kind), [.fiveMinute])
        XCTAssertTrue(ticker.firedKeys.contains(due[0].firedKey))
    }

    func testSameAlertNotReturnedTwice() {
        let ticker = AlertTicker()
        let m = meeting(startingIn: 4 * 60)
        _ = ticker.tick(meetings: [m], now: now)
        XCTAssertEqual(ticker.tick(meetings: [m], now: now.addingTimeInterval(1)), [])
    }

    func testOneMinuteFiresAfterFiveMinute() {
        let ticker = AlertTicker()
        let m = meeting(startingIn: 4 * 60)
        _ = ticker.tick(meetings: [m], now: now)
        let due = ticker.tick(meetings: [m], now: now.addingTimeInterval(3.5 * 60))
        XCTAssertEqual(due.map(\.kind), [.oneMinute])
    }

    func testNothingDueReturnsEmpty() {
        let ticker = AlertTicker()
        XCTAssertEqual(ticker.tick(meetings: [meeting(startingIn: 10 * 60)], now: now), [])
        XCTAssertTrue(ticker.firedKeys.isEmpty)
    }

    func testPrunesKeysOlderThanAnHour() {
        let old = ScheduledAlert(meeting: meeting("old", startingIn: -2 * 3600), kind: .fiveMinute).firedKey
        let recent = ScheduledAlert(meeting: meeting("recent", startingIn: -10 * 60), kind: .fiveMinute).firedKey
        let ticker = AlertTicker(firedKeys: [old, recent])
        _ = ticker.tick(meetings: [], now: now)
        XCTAssertEqual(ticker.firedKeys, [recent])
    }

    func testRescheduledMeetingFiresAgain() {
        let ticker = AlertTicker()
        XCTAssertEqual(ticker.tick(meetings: [meeting(startingIn: 4 * 60)], now: now).count, 1)
        let moved = meeting(startingIn: 14 * 60)
        let later = now.addingTimeInterval(10 * 60)
        XCTAssertEqual(ticker.tick(meetings: [moved], now: later).map(\.kind), [.fiveMinute])
    }
}
