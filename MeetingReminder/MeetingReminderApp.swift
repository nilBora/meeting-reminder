import Combine
import SwiftUI

@main
struct MeetingReminderApp: App {
    @StateObject private var calendarService = CalendarService()
    @StateObject private var meetingMonitor: MeetingMonitor
    @StateObject private var overlayCoordinator: OverlayCoordinator

    init() {
        let calendar = CalendarService()
        let monitor = MeetingMonitor(calendarService: calendar)
        let coordinator = OverlayCoordinator(monitor: monitor)
        _calendarService = StateObject(wrappedValue: calendar)
        _meetingMonitor = StateObject(wrappedValue: monitor)
        _overlayCoordinator = StateObject(wrappedValue: coordinator)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                calendarService: calendarService,
                meetingMonitor: meetingMonitor
            )
            .onAppear {
                Task {
                    await calendarService.requestAccess()
                    calendarService.startMonitoring()
                    meetingMonitor.start()
                    overlayCoordinator.startObserving()
                }
            }
        } label: {
            Label("Meeting Reminder", systemImage: "calendar.badge.clock")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(calendarService: calendarService)
        }
    }
}

@MainActor
final class OverlayCoordinator: ObservableObject {
    private let monitor: MeetingMonitor
    private let windowController = OverlayWindowController()
    private var cancellable: AnyCancellable?

    init(monitor: MeetingMonitor) {
        self.monitor = monitor
    }

    func startObserving() {
        cancellable = monitor.$shouldShowOverlay
            .receive(on: RunLoop.main)
            .sink { [weak self] shouldShow in
                guard let self else { return }
                if shouldShow, let event = monitor.activeOverlayEvent {
                    windowController.show(
                        event: event,
                        onDismiss: { [weak self] in self?.monitor.dismiss() },
                        onSnooze: { [weak self] in self?.monitor.snooze() },
                        onJoin: { [weak self] in self?.monitor.joinMeeting() }
                    )
                } else {
                    windowController.close()
                }
            }
    }
}
