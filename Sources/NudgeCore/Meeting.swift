import Foundation

/// One calendar event Nudge may alert for.
public struct Meeting: Equatable, Hashable {
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let location: String?
    public let isAllDay: Bool
    public let isDeclined: Bool
    /// The event's URL field, if any.
    public let url: URL?
    /// The event's notes as stored (may contain HTML).
    public let notes: String?

    public init(id: String, title: String, start: Date, end: Date,
                location: String? = nil, isAllDay: Bool = false, isDeclined: Bool = false,
                url: URL? = nil, notes: String? = nil) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.isAllDay = isAllDay
        self.isDeclined = isDeclined
        self.url = url
        self.notes = notes
    }

    /// Link the Join buttons open; nil when the event has none.
    public var joinLink: URL? { JoinLink.find(url: url, location: location, notes: notes) }

    /// Cleaned start of the notes for S01/S02/S03; nil when nothing is left.
    public var summary: String? { MeetingNotes.summary(notes) }

    /// Identifies this occurrence: recurring instances and rescheduled meetings get a new key.
    public var alertKey: String { "\(id)|\(start.timeIntervalSince1970)" }
}
