import SwiftUI

struct MenuBarView: View {
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var meetingMonitor: MeetingMonitor
    @Environment(\.dismiss) private var dismiss

    private var upcomingEvents: [MeetingEvent] {
        calendarService.events.filter { $0.timeUntilStart > -300 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if calendarService.authorizationStatus != .authorized {
                calendarAccessSection
            } else if upcomingEvents.isEmpty {
                noEventsSection
            } else {
                eventListSection
            }

            Divider()
                .padding(.vertical, 6)

            PreferencesButton {
                dismiss()
            }

            Divider()
                .padding(.vertical, 6)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit Meeting Reminder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 280)
    }

    // MARK: - Sections

    private var calendarAccessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Calendar Access Required", systemImage: "calendar.badge.exclamationmark")
                .font(.headline)
            Text("Grant access in System Settings → Privacy & Security → Calendars")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Request Access") {
                Task { await calendarService.requestAccess() }
            }
            .controlSize(.small)
        }
    }

    private var noEventsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("No upcoming meetings", systemImage: "checkmark.circle")
                .font(.headline)
            Text("You're free for the rest of the day")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var eventListSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Upcoming Meetings")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            ForEach(upcomingEvents.prefix(5)) { event in
                eventRow(event)
                if event.id != upcomingEvents.prefix(5).last?.id {
                    Divider().padding(.vertical, 2)
                }
            }
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: MeetingEvent) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(event.formattedStartTime)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if event.isInProgress {
                        Text("· In progress")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    } else {
                        Text("· in \(event.formattedTimeUntil)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let url = event.videoLink {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "video.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                .help("Join \(VideoLinkDetector.serviceName(for: url))")
            }
        }
        .padding(.vertical, 2)
    }

}

private struct PreferencesButton: View {
    var onDismiss: () -> Void

    var body: some View {
        if #available(macOS 14.0, *) {
            PreferencesButton14(onDismiss: onDismiss)
        } else {
            Button {
                onDismiss()
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("Preferences…")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
    }
}

@available(macOS 14.0, *)
private struct PreferencesButton14: View {
    @Environment(\.openSettings) private var openSettings
    var onDismiss: () -> Void

    var body: some View {
        Button {
            openSettings()
            onDismiss()
        } label: {
            Text("Preferences…")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
