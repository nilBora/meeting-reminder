import Foundation

/// Decides whether a calendar event should trigger a reminder.
/// Pure logic with no EventKit dependency so it can be unit-tested directly.
enum ReminderFilter {
    static let meetingsOnlyKey = "meetingsOnly"
    static let skipFreeEventsKey = "skipFreeEvents"
    static let excludedKeywordsKey = "excludedTitleKeywords"

    static func triggersReminder(
        title: String,
        hasVideoLink: Bool,
        otherAttendeeCount: Int,
        isFree: Bool,
        meetingsOnly: Bool,
        skipFree: Bool,
        excludedKeywords: [String]
    ) -> Bool {
        if skipFree && isFree { return false }

        let matchesKeyword = excludedKeywords.contains { keyword in
            !keyword.isEmpty && title.range(
                of: keyword,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) != nil
        }
        if matchesKeyword { return false }

        if meetingsOnly && !hasVideoLink && otherAttendeeCount == 0 { return false }

        return true
    }

    /// Splits a comma-separated string into trimmed, non-empty keywords.
    static func parseKeywords(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
}
