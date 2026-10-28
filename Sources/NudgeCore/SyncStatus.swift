import Foundation

/// Where calendar sync stands; S01 renders this.
public enum SyncStatus: Equatable {
    case syncing
    case synced(at: Date)
    /// `savedAt` is when the meetings Nudge is still alerting from were fetched; nil if never.
    case error(CalendarSourceError, savedAt: Date?)
    case noAccess
}
