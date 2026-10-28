#if os(macOS)
import AppKit
import EventKit
import NudgeCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let selectedCalendarKey = "selectedCalendarID"
    static let tickInterval: TimeInterval = 1
    static let refreshInterval: TimeInterval = 60

    let source = EventKitSource()
    let coordinator: SyncCoordinator
    let ticker = AlertTicker()
    var alertPresenter: AlertPresenting = LoggingAlertPresenter()
    var syncObserver: SyncObserving = LoggingSyncObserver()
    private let defaults: UserDefaults
    private var tickTimer: Timer?
    private var refreshTimer: Timer?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        coordinator = SyncCoordinator(source: source,
                                      savedCalendarID: defaults.string(forKey: Self.selectedCalendarKey))
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        coordinator.onStatusChange = { [weak self] _ in
            guard let self else { return }
            self.syncObserver.syncDidChange(self.coordinator)
        }
        tickTimer = schedule(every: Self.tickInterval) { [weak self] in self?.tick() }
        refreshTimer = schedule(every: Self.refreshInterval) { [weak self] in self?.refresh() }
        NotificationCenter.default.addObserver(self, selector: #selector(calendarStoreChanged(_:)),
                                               name: .EKEventStoreChanged, object: source.store)
        // Wake notifications are posted on the workspace center only.
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(didWake(_:)),
                                                          name: NSWorkspace.didWakeNotification, object: nil)
        refresh()
        tick()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tickTimer?.invalidate()
        refreshTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    /// Added in `.common` mode so it keeps running while a menu is open.
    private func schedule(every interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let timer = Timer(timeInterval: interval, repeats: true) { _ in block() }
        timer.tolerance = interval / 10
        RunLoop.main.add(timer, forMode: .common)
        return timer
    }

    func tick(now: Date = Date()) {
        for alert in ticker.tick(meetings: coordinator.meetings, now: now) {
            alertPresenter.present(alert, now: now)
        }
        alertPresenter.tick(now: now)
    }

    func refresh() {
        coordinator.refresh(now: Date())
    }

    @objc private func calendarStoreChanged(_ note: Notification) {
        refresh()
    }

    @objc private func didWake(_ note: Notification) {
        refresh()
        tick()
    }

    /// Used by the S01 "Allow calendar access…" row.
    func requestCalendarAccess() {
        source.requestAccess { [weak self] _ in self?.refresh() }
    }

    /// Used by the S01 Calendar submenu. Only a user's pick is saved, never the automatic fallback.
    func selectCalendar(id: String) {
        defaults.set(id, forKey: Self.selectedCalendarKey)
        coordinator.savedCalendarID = id
        refresh()
    }
}
#endif
