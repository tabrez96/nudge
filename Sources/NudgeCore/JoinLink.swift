import Foundation

/// Finds the link a Join button opens.
public enum JoinLink {
    /// The URL field if it is a web link, else the first conferencing link (Meet, Zoom, Teams) in the
    /// location then the notes, else the first https link there. Nil when there is none.
    public static func find(url: URL?, location: String?, notes: String?) -> URL? {
        if let url, let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https",
           let host = url.host, !host.isEmpty {
            return url
        }
        let candidates = links(in: location ?? "") + links(in: notes ?? "")
        return candidates.first(where: isConferencing) ?? candidates.first
    }

    static func links(in text: String) -> [URL] {
        guard let regex = try? NSRegularExpression(pattern: "https://[^\\s<>\"'\\[\\]]+", options: .caseInsensitive)
        else { return [] }
        let ns = text as NSString
        let trailing = CharacterSet(charactersIn: ".,;:!?)}'\"")
        var result: [URL] = []
        for match in regex.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            var raw = ns.substring(with: match.range).replacingOccurrences(of: "&amp;", with: "&")
            while let last = raw.unicodeScalars.last, trailing.contains(last) {
                raw.unicodeScalars.removeLast()
            }
            if let url = URL(string: raw), url.scheme?.lowercased() == "https",
               let host = url.host, !host.isEmpty {
                result.append(url)
            }
        }
        return result
    }

    static func isConferencing(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "meet.google.com" || host == "zoom.us" || host.hasSuffix(".zoom.us")
            || host == "teams.microsoft.com" || host == "teams.live.com"
    }
}
