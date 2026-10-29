import Foundation

/// Whether macOS lets Nudge show S03 banners. The macOS shell maps `UNNotificationSettings` onto this.
public enum NotificationAccess: Equatable {
    case notDetermined, allowed, denied

    /// `status` mirrors `UNAuthorizationStatus`; `alertsEnabled` is false when the user picked
    /// alert style "None" (`alertSetting == .disabled`), which hides banners even when authorized.
    public static func from(status: NotificationAuthorization, alertsEnabled: Bool) -> NotificationAccess {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional: return alertsEnabled ? .allowed : .denied
        }
    }

    /// S01 shows its warning row only once the user has actually turned banners off; while the
    /// system prompt is still pending there is nothing to warn about.
    public var notificationsAllowed: Bool { self != .denied }
}

/// Platform-free copy of `UNAuthorizationStatus` (`.ephemeral` maps to `.authorized`).
public enum NotificationAuthorization: Equatable { case notDetermined, denied, authorized, provisional }
