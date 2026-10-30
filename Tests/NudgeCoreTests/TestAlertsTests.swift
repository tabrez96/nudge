import XCTest
@testable import NudgeCore

final class TestAlertsTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    func testFirstStepIsBannerNow() {
        let step = TestAlerts.steps(now: now)[0]
        XCTAssertEqual(step.delay, 0)
        XCTAssertEqual(step.alert.kind, .fiveMinute)
        XCTAssertEqual(step.alert.meeting.start, now.addingTimeInterval(300))
        XCTAssertEqual(AlertText.bannerTitle(for: step.alert.meeting), "Test meeting in 5 minutes")
    }

    func testSecondStepIsFullScreenAfterDelay() {
        let step = TestAlerts.steps(now: now)[1]
        XCTAssertEqual(step.delay, TestAlerts.fullScreenDelay)
        XCTAssertEqual(step.delay, 5)
        XCTAssertEqual(step.alert.kind, .oneMinute)
        XCTAssertEqual(AlertText.countdown(until: step.alert.meeting.start, now: now.addingTimeInterval(5)), "1:00")
    }

    func testStepsMatchEngineWindows() {
        let steps = TestAlerts.steps(now: now)
        let first = AlertEngine.dueAlerts(meetings: [steps[0].alert.meeting], now: now, firedKeys: [])
        XCTAssertEqual(first.map(\.kind), [.fiveMinute])
        let second = AlertEngine.dueAlerts(meetings: [steps[1].alert.meeting], now: now.addingTimeInterval(5),
                                           firedKeys: [])
        XCTAssertEqual(second.map(\.kind), [.oneMinute])
    }

    func testFullScreenWarningShowsTestMeeting() {
        let steps = TestAlerts.steps(now: now)
        let warning = FullScreenWarning()
        XCTAssertTrue(warning.show(steps[1].alert))
        let content = warning.content(now: now.addingTimeInterval(5), calendar: utc)
        XCTAssertEqual(content?.heading, "Starting in")
        XCTAssertEqual(content?.countdown, "1:00")
        XCTAssertEqual(content?.title, "Test meeting")
    }

    func testDoesNotChangeTickerFiredKeys() {
        let ticker = AlertTicker()
        let real = Meeting(id: "real", title: "Standup", start: now.addingTimeInterval(240),
                           end: now.addingTimeInterval(2040))
        XCTAssertEqual(ticker.tick(meetings: [real], now: now).count, 1)
        let before = ticker.firedKeys
        XCTAssertEqual(before.count, 1)
        let steps = TestAlerts.steps(now: now)
        XCTAssertEqual(ticker.firedKeys, before)
        for step in steps { XCTAssertFalse(ticker.firedKeys.contains(step.alert.firedKey)) }
        let later = Meeting(id: "later", title: "Sync", start: now.addingTimeInterval(180 + 5),
                            end: now.addingTimeInterval(2000))
        let due = ticker.tick(meetings: [real, later], now: now.addingTimeInterval(5))
        XCTAssertEqual(due.map(\.meeting.id), ["later"])
    }

    func testEachRunHasDistinctKeys() {
        let keys = (TestAlerts.steps(now: now) + TestAlerts.steps(now: now.addingTimeInterval(10))).map(\.alert.firedKey)
        XCTAssertEqual(Set(keys).count, 4)
    }
}
