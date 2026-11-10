import Foundation

/// Turns an event's stored notes (plain text or HTML) into the short description S01, S02 and S03 show.
public enum MeetingNotes {
    public static let maxSummaryLength = 200

    static let boilerplatePrefixes: [String] = [
        "Join with Google Meet", "Join Google Meet", "Join by phone", "Join Zoom Meeting", "Join on your computer",
        "Join the meeting", "Click here to join", "Microsoft Teams meeting", "Meeting ID", "Passcode", "Password:",
        "PIN:", "Phone conference ID", "Dial-in", "Dial in", "Dial by your location", "Or dial", "One tap mobile",
        "More phone numbers", "Find your local number", "Learn more about Meet", "Invitation from Google Calendar",
        "Need help",
    ]

    /// Nil when nothing readable is left after removing links, join instructions and dial-in numbers.
    public static func summary(_ notes: String?) -> String? {
        guard let notes, !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let lines = plainText(notes)
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var kept: [String] = []
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("-::~") { break }
            if isKept(t) { kept.append(t) }
        }
        let joined = replace(kept.joined(separator: " "), "\\s+", " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if joined.isEmpty { return nil }
        guard joined.count > maxSummaryLength else { return joined }
        let head = String(joined.prefix(maxSummaryLength - 1)).trimmingCharacters(in: .whitespacesAndNewlines)
        return head + "…"
    }

    private static func isKept(_ t: String) -> Bool {
        if t.isEmpty { return false }
        let withoutLinks = replace(t, "https?://\\S+", "")
        guard withoutLinks.unicodeScalars.contains(where: { CharacterSet.alphanumerics.contains($0) }) else {
            return false
        }
        let lower = t.lowercased()
        if boilerplatePrefixes.contains(where: { lower.hasPrefix($0.lowercased()) }) { return false }
        if lower.contains("tel:") { return false }
        if t.range(of: "\\+\\d[\\d\\s().-]{6,}", options: .regularExpression) != nil { return false }
        return true
    }

    private static func plainText(_ html: String) -> String {
        var text = replace(html, "<br\\s*/?>", "\n", caseInsensitive: true)
        text = replace(text, "</(p|div|li|tr|h[1-6])>", "\n", caseInsensitive: true)
        text = replace(text, "<[^>]+>", "")
        for (entity, plain) in [("&nbsp;", " "), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""),
                                ("&#39;", "'"), ("&apos;", "'"), ("&amp;", "&")] {
            text = text.replacingOccurrences(of: entity, with: plain)
        }
        return text
    }

    private static func replace(_ text: String, _ pattern: String, _ template: String,
                                caseInsensitive: Bool = false) -> String {
        text.replacingOccurrences(of: pattern, with: template,
                                  options: caseInsensitive ? [.regularExpression, .caseInsensitive] : .regularExpression)
    }
}
