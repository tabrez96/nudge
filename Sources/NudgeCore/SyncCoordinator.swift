import Foundation

/// Owns the last good meeting list and the sync status. Call from one thread (the main thread in the app).
public final class SyncCoordinator {
    public static let lookBack: TimeInterval = 5 * 60

    public private(set) var meetings: [Meeting] = []
    public private(set) var status: SyncStatus = .noAccess
    public private(set) var calendars: [CalendarInfo] = []
    public private(set) var chosenCalendar: CalendarInfo?
    public private(set) var lastSyncedAt: Date?
    /// The user's pick from S01; the app persists it in UserDefaults.
    public var savedCalendarID: String?
    /// Called every time `status` changes, including the `.syncing` step.
    public var onStatusChange: ((SyncStatus) -> Void)?

    private let source: any CalendarSource
    private let calendar: Calendar

    public init(source: any CalendarSource, savedCalendarID: String? = nil, calendar: Calendar = .current) {
        self.source = source
        self.savedCalendarID = savedCalendarID
        self.calendar = calendar
    }

    /// Re-reads the chosen calendar. Only a successful fetch replaces `meetings`; a vanished calendar is an error.
    public func refresh(now: Date) {
        setStatus(.syncing)
        guard source.authorization() == .granted else {
            calendars = []
            chosenCalendar = nil
            setStatus(.noAccess)
            return
        }
        calendars = source.calendars()
        let chosen: CalendarInfo
        switch CalendarChoice.resolve(savedID: savedCalendarID, previous: chosenCalendar, from: calendars) {
        case .none:
            chosenCalendar = nil
            setStatus(.noAccess)
            return
        case .missing:
            // Keep `chosenCalendar` and `meetings`: alerts carry on from saved data until it comes back.
            setStatus(.error(.calendarNotFound, savedAt: lastSyncedAt))
            return
        case .use(let calendar):
            chosen = calendar
        }
        chosenCalendar = chosen
        let window = Self.fetchWindow(now: now, calendar: calendar)
        do {
            let fetched = try source.meetings(calendarID: chosen.id, from: window.from, to: window.to)
            meetings = fetched.sorted { ($0.start, $0.id) < ($1.start, $1.id) }
            lastSyncedAt = now
            setStatus(.synced(at: now))
        } catch {
            let kind = (error as? CalendarSourceError) ?? .fetchFailed
            setStatus(.error(kind, savedAt: lastSyncedAt))
        }
    }

    /// Fetch range: 5 minutes before `now` up to midnight at the end of tomorrow.
    public static func fetchWindow(now: Date, calendar: Calendar) -> (from: Date, to: Date) {
        let from = now.addingTimeInterval(-lookBack)
        let to = calendar.date(byAdding: .day, value: 2, to: calendar.startOfDay(for: now))!
        return (from, to)
    }

    private func setStatus(_ newStatus: SyncStatus) {
        status = newStatus
        onStatusChange?(newStatus)
    }
}
