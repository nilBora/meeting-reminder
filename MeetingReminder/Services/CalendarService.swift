import Combine
import EventKit
import Foundation

@MainActor
final class CalendarService: ObservableObject {
    @Published var events: [MeetingEvent] = []
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []

    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    private var notificationObserver: Any?

    init() {
        updateAuthorizationStatus()
        setupNotificationObserver()
    }

    deinit {
        refreshTimer?.invalidate()
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                updateAuthorizationStatus()
                if granted {
                    fetchEvents()
                    startAutoRefresh()
                }
            } catch {
                print("Calendar access error: \(error)")
            }
        } else {
            let granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            updateAuthorizationStatus()
            if granted {
                fetchEvents()
                startAutoRefresh()
            }
        }
    }

    func startMonitoring() {
        fetchEvents()
        startAutoRefresh()
    }

    func fetchEvents() {
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!

        let predicate = eventStore.predicateForEvents(
            withStart: now.addingTimeInterval(-300), // include events that just started
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        let enabledCalendarIDs = Set(
            UserDefaults.standard.stringArray(forKey: "enabledCalendarIDs") ?? []
        )

        events = ekEvents
            .filter { event in
                // Filter out all-day events
                guard !event.isAllDay else { return false }

                // Filter out declined events
                if let attendees = event.attendees,
                   let me = attendees.first(where: { $0.isCurrentUser }),
                   me.participantStatus == .declined {
                    return false
                }

                // Filter by enabled calendars (if any are configured)
                if !enabledCalendarIDs.isEmpty {
                    return enabledCalendarIDs.contains(event.calendar.calendarIdentifier)
                }

                return true
            }
            .map { ekEvent in
                let videoLink = VideoLinkDetector.detectLink(in: ekEvent)
                return MeetingEvent(from: ekEvent, videoLink: videoLink)
            }
            .sorted { $0.startDate < $1.startDate }

        availableCalendars = eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func updateAuthorizationStatus() {
        if #available(macOS 14.0, *) {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        } else {
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        }
    }

    private func startAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }

    private func setupNotificationObserver() {
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.fetchEvents()
            }
        }
    }
}
