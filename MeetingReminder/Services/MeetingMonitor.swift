import AppKit
import Combine
import Foundation

@MainActor
final class MeetingMonitor: ObservableObject {
    @Published var activeOverlayEvent: MeetingEvent?
    @Published var shouldShowOverlay = false

    private var calendarService: CalendarService
    private var checkTimer: Timer?
    private var shownEventIDs: Set<String> = []
    private var snoozedEvents: [String: Date] = [:]
    private var cancellables = Set<AnyCancellable>()

    var reminderMinutes: Int {
        UserDefaults.standard.integer(forKey: "reminderMinutes").clamped(to: 1...30, default: 5)
    }

    init(calendarService: CalendarService) {
        self.calendarService = calendarService
    }

    func start() {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkUpcomingMeetings()
            }
        }
        // Also check immediately
        checkUpcomingMeetings()
    }

    func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    func dismiss() {
        shouldShowOverlay = false
        activeOverlayEvent = nil
    }

    func snooze(minutes: Int = 1) {
        guard let event = activeOverlayEvent else { return }
        snoozedEvents[event.id] = Date().addingTimeInterval(TimeInterval(minutes * 60))
        shownEventIDs.remove(event.id)
        dismiss()
    }

    func joinMeeting() {
        guard let event = activeOverlayEvent, let url = event.videoLink else { return }
        NSWorkspace.shared.open(url)
        dismiss()
    }

    private func checkUpcomingMeetings() {
        let now = Date()
        let reminderSeconds = TimeInterval(reminderMinutes * 60)

        // Clean up expired snoozes and old shown IDs
        snoozedEvents = snoozedEvents.filter { $0.value > now }

        for event in calendarService.events {
            let timeUntil = event.startDate.timeIntervalSince(now)

            // Skip if already shown
            guard !shownEventIDs.contains(event.id) else { continue }

            // Skip if snoozed and snooze hasn't expired
            if let snoozeUntil = snoozedEvents[event.id], now < snoozeUntil {
                continue
            }

            // Trigger overlay if event is within reminder window
            if timeUntil > 0 && timeUntil <= reminderSeconds {
                triggerOverlay(for: event)
                return
            }

            // Also trigger for events that just started (within 60 seconds)
            if timeUntil <= 0 && timeUntil > -60 {
                triggerOverlay(for: event)
                return
            }
        }
    }

    private func triggerOverlay(for event: MeetingEvent) {
        shownEventIDs.insert(event.id)
        activeOverlayEvent = event
        shouldShowOverlay = true

        if UserDefaults.standard.object(forKey: "soundEnabled") == nil ||
           UserDefaults.standard.bool(forKey: "soundEnabled") {
            NSSound.beep()
        }
    }
}

extension Int {
    func clamped(to range: ClosedRange<Int>, default defaultValue: Int) -> Int {
        if self == 0 { return defaultValue }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
