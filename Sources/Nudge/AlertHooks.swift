#if os(macOS)
import Foundation
import NudgeCore

/// Shows alerts. Implemented by the S03 notifier and the S02 full-screen controller in later tickets.
protocol AlertPresenting: AnyObject {
    /// Called once per due alert, already marked fired.
    func present(_ alert: ScheduledAlert, now: Date)
    /// Called every second so an open S02 window can update its countdown.
    func tick(now: Date)
}

/// Shows sync state. Implemented by the S01 menu controller.
protocol SyncObserving: AnyObject {
    func syncDidChange(_ coordinator: SyncCoordinator)
}

/// Placeholder until the real alert UI exists: logs each alert.
final class LoggingAlertPresenter: AlertPresenting {
    func present(_ alert: ScheduledAlert, now: Date) {
        NSLog("Nudge alert %@: %@ at %@", alert.kind.rawValue, alert.meeting.title, "\(alert.meeting.start)")
    }

    func tick(now: Date) {}
}

/// Fallback used before the menu controller is installed.
final class LoggingSyncObserver: SyncObserving {
    func syncDidChange(_ coordinator: SyncCoordinator) {
        NSLog("Nudge sync status: %@", "\(coordinator.status)")
    }
}
#endif
