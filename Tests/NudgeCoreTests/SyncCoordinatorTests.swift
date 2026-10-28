import XCTest
@testable import NudgeCore

private struct Boom: Error {}

final class SyncCoordinatorTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var utc: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()
    private var fake = FakeCalendarSource()

    override func setUp() {
        fake = FakeCalendarSource()
    }

    private func makeCoordinator(savedID: String? = nil) -> SyncCoordinator {
        SyncCoordinator(source: fake, savedCalendarID: savedID, calendar: utc)
    }

    private func meeting(_ id: String, minutes: TimeInterval) -> Meeting {
        let start = now.addingTimeInterval(minutes * 60)
        return Meeting(id: id, title: "Standup", start: start, end: start.addingTimeInterval(1800))
    }

    func testSuccessReplacesMeetingsAndSetsSynced() {
        let c = makeCoordinator()
        fake.result = .success([meeting("a", minutes: 10)])
        c.refresh(now: now)
        let second = [meeting("b", minutes: 20)]
        fake.result = .success(second)
        c.refresh(now: now.addingTimeInterval(60))
        XCTAssertEqual(c.meetings, second)
        XCTAssertEqual(c.status, .synced(at: now.addingTimeInterval(60)))
    }

    func testFetchUsesWindowFromFiveMinutesAgoToEndOfTomorrow() {
        makeCoordinator().refresh(now: now)
        let f = fake.fetches.last
        XCTAssertEqual(f?.from, Date(timeIntervalSince1970: 1_799_999_700))
        XCTAssertEqual(f?.to, Date(timeIntervalSince1970: 1_800_144_000))
        XCTAssertEqual(f?.calendarID, "cal1")
    }

    func testFetchUsesChosenCalendar() {
        let cal1 = fake.calendarList[0]
        let cal2 = CalendarInfo(id: "cal2", title: "Team", sourceTitle: "Google")
        fake.calendarList = [cal2, cal1]
        let c = makeCoordinator(savedID: "cal2")
        c.refresh(now: now)
        XCTAssertEqual(fake.fetches.last?.calendarID, "cal2")
        XCTAssertEqual(c.chosenCalendar?.id, "cal2")
        fake.calendarList = [cal1]
        c.refresh(now: now)
        XCTAssertEqual(fake.fetches.last?.calendarID, "cal1")
        XCTAssertEqual(c.savedCalendarID, "cal2")
    }

    func testFailureKeepsPreviousMeetingsAndSavedAt() {
        let c = makeCoordinator()
        let list = [meeting("a", minutes: 10)]
        fake.result = .success(list)
        c.refresh(now: now)
        fake.result = .failure(CalendarSourceError.fetchFailed)
        c.refresh(now: now.addingTimeInterval(60))
        XCTAssertEqual(c.meetings, list)
        XCTAssertEqual(c.status, .error(.fetchFailed, savedAt: now))
    }

    func testSecondFailureKeepsOriginalSavedAt() {
        let c = makeCoordinator()
        c.refresh(now: now)
        fake.result = .failure(CalendarSourceError.fetchFailed)
        c.refresh(now: now.addingTimeInterval(60))
        c.refresh(now: now.addingTimeInterval(120))
        XCTAssertEqual(c.status, .error(.fetchFailed, savedAt: now))
    }

    func testFailureBeforeAnySuccessHasNilSavedAt() {
        let c = makeCoordinator()
        fake.result = .failure(CalendarSourceError.calendarNotFound)
        c.refresh(now: now)
        XCTAssertEqual(c.status, .error(.calendarNotFound, savedAt: nil))
        XCTAssertEqual(c.meetings, [])
    }

    func testUnknownErrorMapsToFetchFailed() {
        let c = makeCoordinator()
        fake.result = .failure(Boom())
        c.refresh(now: now)
        XCTAssertEqual(c.status, .error(.fetchFailed, savedAt: nil))
    }

    func testThrownAccessDeniedIsError() {
        let c = makeCoordinator()
        fake.result = .failure(CalendarSourceError.accessDenied)
        c.refresh(now: now)
        XCTAssertEqual(c.status, .error(.accessDenied, savedAt: nil))
    }

    func testDeniedAccessYieldsNoAccess() {
        let c = makeCoordinator()
        fake.access = .denied
        c.refresh(now: now)
        XCTAssertEqual(c.status, .noAccess)
        XCTAssertTrue(fake.fetches.isEmpty)
    }

    func testNotDeterminedAccessYieldsNoAccess() {
        let c = makeCoordinator()
        fake.access = .notDetermined
        c.refresh(now: now)
        XCTAssertEqual(c.status, .noAccess)
        XCTAssertTrue(fake.fetches.isEmpty)
    }

    func testZeroCalendarsYieldsNoAccess() {
        let c = makeCoordinator()
        fake.calendarList = []
        c.refresh(now: now)
        XCTAssertEqual(c.status, .noAccess)
        XCTAssertNil(c.chosenCalendar)
        XCTAssertTrue(fake.fetches.isEmpty)
    }

    func testNoAccessKeepsPreviousMeetings() {
        let c = makeCoordinator()
        let list = [meeting("a", minutes: 10)]
        fake.result = .success(list)
        c.refresh(now: now)
        fake.access = .denied
        c.refresh(now: now.addingTimeInterval(60))
        XCTAssertEqual(c.meetings, list)
        XCTAssertEqual(c.status, .noAccess)
    }

    func testRecoveryAfterErrorReturnsToSynced() {
        let c = makeCoordinator()
        c.refresh(now: now)
        fake.result = .failure(CalendarSourceError.fetchFailed)
        c.refresh(now: now.addingTimeInterval(60))
        let fresh = [meeting("n", minutes: 30)]
        fake.result = .success(fresh)
        let later = now.addingTimeInterval(120)
        c.refresh(now: later)
        XCTAssertEqual(c.status, .synced(at: later))
        XCTAssertEqual(c.meetings, fresh)
    }

    func testStatusIsSyncingDuringFetch() {
        let c = makeCoordinator()
        var during: SyncStatus?
        var seen: [SyncStatus] = []
        fake.onFetch = { during = c.status }
        c.onStatusChange = { seen.append($0) }
        c.refresh(now: now)
        XCTAssertEqual(during, .syncing)
        XCTAssertEqual(seen, [.syncing, .synced(at: now)])
    }

    func testMeetingsAreSortedByStart() {
        let c = makeCoordinator()
        fake.result = .success([meeting("c", minutes: 30), meeting("a", minutes: 5), meeting("b", minutes: 5)])
        c.refresh(now: now)
        XCTAssertEqual(c.meetings.map(\.id), ["a", "b", "c"])
    }

    func testSuccessWithNoMeetingsIsSynced() {
        let c = makeCoordinator()
        fake.result = .success([meeting("a", minutes: 5), meeting("b", minutes: 6)])
        c.refresh(now: now)
        fake.result = .success([])
        c.refresh(now: now.addingTimeInterval(60))
        XCTAssertEqual(c.meetings, [])
        XCTAssertEqual(c.status, .synced(at: now.addingTimeInterval(60)))
    }
}
