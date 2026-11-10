#if os(macOS)
import AppKit
import NudgeCore
import UserNotifications

/// S03: plays the alert sound and posts the five-minute banner. Ignores other alert kinds.
final class Notifier: NSObject, AlertPresenting, UNUserNotificationCenterDelegate {
    static let soundName = "Glass"
    static let joinCategory = "nudge.join"
    static let joinAction = "nudge.join.open"
    static let joinURLKey = "joinURL"

    /// Called on the main thread whenever the access state is (re)read.
    var onAccessChange: ((NotificationAccess) -> Void)?
    private(set) var access: NotificationAccess = .notDetermined
    private let sound = NSSound(named: Notifier.soundName)
    /// Nil when running outside an app bundle (`swift run Nudge`): `UNUserNotificationCenter.current()`
    /// crashes without a bundle identifier, so banners are skipped and only the sound plays.
    private let center: UNUserNotificationCenter? =
        Bundle.main.bundleIdentifier == nil ? nil : UNUserNotificationCenter.current()

    func start() {
        guard let center else {
            NSLog("Nudge: no app bundle, banners off; sound only")
            report(.denied)
            return
        }
        center.delegate = self
        center.setNotificationCategories([UNNotificationCategory(
            identifier: Self.joinCategory,
            actions: [UNNotificationAction(identifier: Self.joinAction, title: "Join", options: [])],
            intentIdentifiers: [], options: [])])
        // Alert only: the sound is played by NSSound, so it can never play twice.
        center.requestAuthorization(options: [.alert]) { [weak self] _, error in
            if let error { NSLog("Nudge: notification authorization failed: %@", "\(error)") }
            self?.refreshAccess()
        }
    }

    func refreshAccess() {
        guard let center else { return }
        center.getNotificationSettings { [weak self] settings in
            let status: NotificationAuthorization
            switch settings.authorizationStatus {
            case .notDetermined: status = .notDetermined
            case .denied: status = .denied
            case .authorized: status = .authorized
            case .provisional: status = .provisional
            default: status = .authorized
            }
            let access = NotificationAccess.from(status: status,
                                                 alertsEnabled: settings.alertSetting != .disabled && settings.alertStyle != .none)
            DispatchQueue.main.async { self?.report(access) }
        }
    }

    private func report(_ access: NotificationAccess) {
        self.access = access
        onAccessChange?(access)
    }

    func present(_ alert: ScheduledAlert, now: Date) {
        guard alert.kind == .fiveMinute else { return }
        // Sound first and unconditionally, so it plays even when banners are denied.
        if let sound {
            sound.stop()
            sound.play()
        } else {
            NSSound.beep()
        }
        guard let center else { return }
        let content = UNMutableNotificationContent()
        content.title = AlertText.bannerTitle(for: alert.meeting)
        content.subtitle = AlertText.bannerSubtitle(for: alert.meeting)
        content.body = alert.meeting.summary ?? ""
        if let url = alert.meeting.joinLink {
            content.categoryIdentifier = Self.joinCategory
            content.userInfo = [Self.joinURLKey: url.absoluteString]
        }
        // Posting while denied is harmless (the system drops it), so a stale `access` can't swallow a banner.
        let request = UNNotificationRequest(identifier: alert.firedKey, content: content, trigger: nil)
        center.add(request) { error in
            if let error { NSLog("Nudge: could not post banner: %@", "\(error)") }
        }
        refreshAccess()
    }

    func tick(now: Date) {}

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list])
    }

    /// Clicking the banner only dismisses it; its Join action opens the link (S03).
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == Self.joinAction,
           let string = response.notification.request.content.userInfo[Self.joinURLKey] as? String,
           let url = URL(string: string) {
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
        }
        completionHandler()
    }
}
#endif
