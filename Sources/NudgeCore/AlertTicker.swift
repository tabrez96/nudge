import Foundation

/// Remembers which alerts have fired and hands out the ones that are due. Call from one thread.
public final class AlertTicker {
    public private(set) var firedKeys: Set<String>

    public init(firedKeys: Set<String> = []) {
        self.firedKeys = firedKeys
    }

    /// Alerts due at `now` that haven't fired yet, in `AlertEngine` order. Marks them fired and
    /// drops keys for meetings that started over an hour ago.
    public func tick(meetings: [Meeting], now: Date) -> [ScheduledAlert] {
        firedKeys = AlertEngine.pruneFiredKeys(firedKeys, now: now)
        let due = AlertEngine.dueAlerts(meetings: meetings, now: now, firedKeys: firedKeys)
        for alert in due { firedKeys.insert(alert.firedKey) }
        return due
    }
}
