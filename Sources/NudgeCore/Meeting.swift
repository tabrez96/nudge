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

    public init(id: String, title: String, start: Date, end: Date,
                location: String? = nil, isAllDay: Bool = false, isDeclined: Bool = false) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.isAllDay = isAllDay
        self.isDeclined = isDeclined
    }

    /// Identifies this occurrence: recurring instances and rescheduled meetings get a new key.
    public var alertKey: String { "\(id)|\(start.timeIntervalSince1970)" }
}
