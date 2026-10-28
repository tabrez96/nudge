#if os(macOS)
import EventKit
import Foundation
import NudgeCore

/// `CalendarSource` backed by the calendars macOS syncs (Google via Internet Accounts).
final class EventKitSource: CalendarSource {
    static let untitledTitle = "Untitled meeting"
    let store = EKEventStore()

    func authorization() -> CalendarAccess {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(macOS 14, *) {
            switch status {
            case .fullAccess: return .granted
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        } else {
            switch status {
            case .authorized: return .granted
            case .notDetermined: return .notDetermined
            default: return .denied
            }
        }
    }

    func calendars() -> [CalendarInfo] {
        store.calendars(for: .event).map {
            CalendarInfo(id: $0.calendarIdentifier, title: $0.title, sourceTitle: $0.source?.title ?? "")
        }
    }

    func meetings(calendarID: String, from: Date, to: Date) throws -> [Meeting] {
        guard authorization() == .granted else { throw CalendarSourceError.accessDenied }
        guard let calendar = store.calendar(withIdentifier: calendarID) else {
            throw CalendarSourceError.calendarNotFound
        }
        let predicate = store.predicateForEvents(withStart: from, end: to, calendars: [calendar])
        return store.events(matching: predicate).compactMap(Self.meeting(from:))
    }

    /// Shows the system prompt. `completion` runs on the main queue.
    func requestAccess(completion: @escaping (Bool) -> Void) {
        let finish: (Bool) -> Void = { granted in
            DispatchQueue.main.async {
                // Re-read calendars that weren't visible before access was granted.
                if granted { self.store.reset() }
                completion(granted)
            }
        }
        if #available(macOS 14, *) {
            store.requestFullAccessToEvents { granted, _ in finish(granted) }
        } else {
            store.requestAccess(to: .event) { granted, _ in finish(granted) }
        }
    }

    /// Maps an event to a `Meeting`; nil for all-day, cancelled and self-declined events.
    static func meeting(from event: EKEvent) -> Meeting? {
        if event.isAllDay { return nil }
        if event.status == .canceled { return nil }
        if event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus == .declined { return nil }

        let title = event.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let location = event.location?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return Meeting(id: event.calendarItemExternalIdentifier ?? event.calendarItemIdentifier,
                       title: title.isEmpty ? untitledTitle : title,
                       start: event.startDate,
                       end: event.endDate,
                       location: location.isEmpty ? nil : location,
                       isAllDay: false,
                       isDeclined: false)
    }
}
#endif
