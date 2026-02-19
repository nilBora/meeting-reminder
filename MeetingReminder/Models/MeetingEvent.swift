import EventKit
import Foundation

struct MeetingEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendar: String
    let calendarColor: String
    let videoLink: URL?
    let isAllDay: Bool

    var timeUntilStart: TimeInterval {
        startDate.timeIntervalSinceNow
    }

    var minutesUntilStart: Int {
        Int(ceil(timeUntilStart / 60))
    }

    var isHappeningSoon: Bool {
        timeUntilStart > 0 && timeUntilStart <= 600
    }

    var isInProgress: Bool {
        let now = Date()
        return now >= startDate && now < endDate
    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }

    var formattedTimeUntil: String {
        let totalMinutes = minutesUntilStart
        if totalMinutes <= 0 {
            return "Now"
        } else if totalMinutes == 1 {
            return "1 minute"
        } else if totalMinutes < 60 {
            return "\(totalMinutes) minutes"
        } else {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours) h"
            } else {
                return "\(hours) h \(minutes) min"
            }
        }
    }

    static func == (lhs: MeetingEvent, rhs: MeetingEvent) -> Bool {
        lhs.id == rhs.id
    }

    init(from ekEvent: EKEvent, videoLink: URL?) {
        // Use eventIdentifier + startDate to uniquely identify recurring event occurrences
        let baseID = ekEvent.eventIdentifier ?? UUID().uuidString
        let dateStamp = ISO8601DateFormatter().string(from: ekEvent.startDate)
        self.id = "\(baseID)_\(dateStamp)"
        self.title = ekEvent.title ?? "Untitled Meeting"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.calendar = ekEvent.calendar.title
        self.calendarColor = ""
        self.videoLink = videoLink
        self.isAllDay = ekEvent.isAllDay
    }

    init(id: String, title: String, startDate: Date, endDate: Date,
         calendar: String, calendarColor: String = "",
         videoLink: URL? = nil, isAllDay: Bool = false) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.calendar = calendar
        self.calendarColor = calendarColor
        self.videoLink = videoLink
        self.isAllDay = isAllDay
    }
}
