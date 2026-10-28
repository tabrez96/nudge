import XCTest
@testable import NudgeCore

final class AlertTextTests: XCTestCase {
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    // 2027-01-15 08:00 UTC
    private let base = Date(timeIntervalSince1970: 1_800_000_000)

    private func meeting(location: String? = "Conference Room B") -> Meeting {
        let start = base.addingTimeInterval(6 * 3600)
        return Meeting(id: "m", title: "Weekly team sync", start: start,
                       end: start.addingTimeInterval(1800), location: location)
    }

    func testBannerTitle() {
        XCTAssertEqual(AlertText.bannerTitle(for: meeting()), "Weekly team sync in 5 minutes")
    }

    func testBannerBodyWithLocation() {
        XCTAssertEqual(AlertText.bannerBody(for: meeting(), calendar: utc), "2:00 PM · Conference Room B")
    }

    func testBannerBodyWithoutLocation() {
        XCTAssertEqual(AlertText.bannerBody(for: meeting(location: nil), calendar: utc), "2:00 PM")
        XCTAssertEqual(AlertText.bannerBody(for: meeting(location: "  "), calendar: utc), "2:00 PM")
    }

    func testTimeRange() {
        XCTAssertEqual(AlertText.timeRange(for: meeting(), calendar: utc), "2:00 PM – 2:30 PM")
    }

    func testFullScreenDetail() {
        XCTAssertEqual(AlertText.fullScreenDetail(for: meeting(), calendar: utc),
                       "2:00 PM – 2:30 PM · Conference Room B")
        XCTAssertEqual(AlertText.fullScreenDetail(for: meeting(location: nil), calendar: utc),
                       "2:00 PM – 2:30 PM")
    }

    func testCountdownSteps() {
        let steps: [(TimeInterval, String)] = [
            (60, "1:00"), (59.2, "1:00"), (59, "0:59"), (1, "0:01"),
            (0.4, "0:01"), (0, "Starting now"), (-5, "Starting now"),
        ]
        for (seconds, expected) in steps {
            XCTAssertEqual(AlertText.countdown(until: base.addingTimeInterval(seconds), now: base),
                           expected, "\(seconds)s")
        }
    }

    func testClockFormatsMorningAndNoon() {
        XCTAssertEqual(TimeText.clock(base.addingTimeInterval(5 * 60), calendar: utc), "8:05 AM")
        XCTAssertEqual(TimeText.clock(base.addingTimeInterval(4 * 3600), calendar: utc), "12:00 PM")
        XCTAssertEqual(TimeText.clock(base.addingTimeInterval(-8 * 3600), calendar: utc), "12:00 AM")
    }
}
