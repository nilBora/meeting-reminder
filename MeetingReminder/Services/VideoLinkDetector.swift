import AppKit
import EventKit
import Foundation

struct VideoLinkDetector {
    private static let patterns: [(name: String, pattern: String)] = [
        ("Zoom", #"https?://[\w.-]*zoom\.us/j/\S+"#),
        ("Google Meet", #"https?://meet\.google\.com/[a-z]+-[a-z]+-[a-z]+\S*"#),
        ("Microsoft Teams", #"https?://teams\.microsoft\.com/l/meetup-join/\S+"#),
        ("Webex", #"https?://[\w.-]*webex\.com/\S+"#),
        ("Slack Huddle", #"https?://app\.slack\.com/huddle/\S+"#),
    ]

    private static let boundedPatterns = [
        #"https?://[\w.-]*zoom\.us/j/[0-9]+(?:\?[^\s<]*)?"#,
        #"https?://teams\.microsoft\.com/l/meetup-join/[^\s<]+?/0(?:\?[^\s<]*)?"#,
    ]

    static func detectLink(in event: EKEvent) -> URL? {
        // Check the event URL first — most reliable source
        if let url = event.url, isVideoLink(url) {
            return url
        }

        // Search through text fields
        let searchTexts = [event.notes, event.location].compactMap { $0 }

        for text in searchTexts {
            if let url = findVideoURL(in: text) {
                return url
            }
        }

        return nil
    }

    static func isVideoLink(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        return patterns.contains { _, pattern in
            urlString.range(of: pattern, options: .regularExpression) != nil
        }
    }

    static func findVideoURL(in text: String) -> URL? {
        for (_, pattern) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }

            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range) {
                let matchRange = Range(match.range, in: text)!
                var urlString = String(text[matchRange])

                // Clean trailing punctuation that might have been captured
                while urlString.hasSuffix(")") || urlString.hasSuffix(">") ||
                      urlString.hasSuffix("\"") || urlString.hasSuffix("'") {
                    urlString = String(urlString.dropLast())
                }

                let cleanedURLString = boundedURLString(in: urlString) ?? urlString
                if let url = URL(string: cleanedURLString) {
                    return url
                }
            }
        }

        return nil
    }

    static func cleanedMeetingURL(for url: URL) -> URL {
        guard let cleanedURLString = boundedURLString(in: url.absoluteString),
              let cleanedURL = URL(string: cleanedURLString) else {
            return url
        }
        return cleanedURL
    }

    static func nativeAppURL(for url: URL) -> URL? {
        let cleanedURL = cleanedMeetingURL(for: url)
        let host = cleanedURL.host?.lowercased() ?? ""

        if host.contains("zoom.us"), let meetingID = zoomMeetingID(in: cleanedURL) {
            var components = URLComponents()
            components.scheme = "zoommtg"
            components.host = host
            components.path = "/join"
            components.queryItems = [URLQueryItem(name: "confno", value: meetingID)]
                + (URLComponents(url: cleanedURL, resolvingAgainstBaseURL: false)?.queryItems ?? [])
            return components.url
        }

        if host.contains("teams.microsoft.com"), isBoundedTeamsMeetingURL(cleanedURL) {
            var components = URLComponents(url: cleanedURL, resolvingAgainstBaseURL: false)
            components?.scheme = "msteams"
            return components?.url
        }

        return nil
    }

    static func preferredMeetingURL(for url: URL) -> URL {
        nativeAppURL(for: url) ?? cleanedMeetingURL(for: url)
    }

    static func openMeetingURL(_ url: URL) {
        let fallbackURL = cleanedMeetingURL(for: url)
        guard let nativeURL = nativeAppURL(for: fallbackURL) else {
            NSWorkspace.shared.open(fallbackURL)
            return
        }

        NSWorkspace.shared.open(nativeURL, configuration: .init()) { _, error in
            if error != nil {
                NSWorkspace.shared.open(fallbackURL)
            }
        }
    }

    static func serviceName(for url: URL) -> String {
        let host = url.host?.lowercased() ?? ""
        if host.contains("zoom.us") { return "Zoom" }
        if host.contains("meet.google.com") { return "Google Meet" }
        if host.contains("teams.microsoft.com") { return "Teams" }
        if host.contains("webex.com") { return "Webex" }
        if host.contains("slack.com") { return "Slack" }
        return "Meeting"
    }

    private static func zoomMeetingID(in url: URL) -> String? {
        let pathComponents = url.pathComponents
        guard let joinIndex = pathComponents.firstIndex(of: "j"),
              joinIndex + 1 < pathComponents.count else {
            return nil
        }

        let meetingID = pathComponents[joinIndex + 1]
        return meetingID.allSatisfy(\.isNumber) ? meetingID : nil
    }

    private static func isBoundedTeamsMeetingURL(_ url: URL) -> Bool {
        let urlString = url.absoluteString
        let pattern = #"^https?://teams\.microsoft\.com/l/meetup-join/[^\s<]+?/0(?:\?[^\s<]*)?$"#
        return urlString.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func boundedURLString(in urlString: String) -> String? {
        for pattern in boundedPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                continue
            }

            let range = NSRange(urlString.startIndex..., in: urlString)
            guard let match = regex.firstMatch(in: urlString, range: range),
                  match.range.location == 0,
                  let matchRange = Range(match.range, in: urlString) else {
                continue
            }

            return String(urlString[matchRange])
        }

        return nil
    }
}
