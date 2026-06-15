import SwiftUI

struct OverlayView: View {
    let event: MeetingEvent
    let kind: OverlayKind
    let onDismiss: () -> Void
    let onSnooze: (Int) -> Void
    let onJoin: () -> Void

    @AppStorage("overlayBackground") private var overlayBackground: String = "dark"
    @AppStorage("overlayOpacity") private var overlayOpacity: Double = 1.0
    @AppStorage("requireAction") private var requireAction: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var countdown: String = ""
    @State private var timer: Timer?
    @State private var snoozeOptions: [Int] = [1, 2, 5, 10]
    @State private var hasEnded: Bool = false
    @State private var availableSnoozeOptions: [Int] = []

    var body: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(currentBackground)
                .opacity(overlayOpacity)

            VStack(spacing: 24) {
                Spacer()

                // Icon (decorative)
                Image(systemName: headerIcon)
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityHidden(true)

                // Meeting title
                Text(event.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Time info
                Text(countdown)
                    .font(.system(size: 28, weight: .medium).monospacedDigit())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(secondaryTimeText)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))

                // Calendar name
                Text(event.calendar)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.top, -8)

                Spacer()

                // Action buttons
                HStack(spacing: 20) {
                    if kind == .start, event.videoLink != nil {
                        Button(action: onJoin) {
                            HStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                Text("Join \(videoServiceName)")
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color(red: 0.13, green: 0.70, blue: 0.42))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(OverlayButtonStyle())
                        .keyboardShortcut(.return, modifiers: [])
                    }


                    if showQuickSnooze {
                        Button(action: { onSnooze(availableSnoozeOptions.first ?? 1) }) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Snooze \(availableSnoozeOptions.first ?? 1) min")
                            }
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }

                    if showSnoozeMenu {
                        Menu {
                            ForEach(availableSnoozeOptions, id: \.self) { minutes in
                                Button(snoozeLabel(minutes: minutes)) {
                                    onSnooze(minutes)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Snooze")
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                        .buttonStyle(OverlayButtonStyle())
                    }


                    if showDismissButton {
                        Button(action: onDismiss) {
                            HStack(spacing: 8) {
                                Image(systemName: dismissIcon)
                                Text(dismissLabel)
                            }
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(OverlayButtonStyle())
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                }

                Spacer()
                    .frame(height: 80)
            }
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .ignoresSafeArea()
        .onAppear {
            let animation: Animation? = reduceMotion
                ? nil
                : .spring(response: 0.45, dampingFraction: 0.75)
            withAnimation(animation) {
                appeared = true
            }
            loadSnoozeOptions()
            refreshAvailability()
            updateCountdown()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    refreshAvailability()
                    updateCountdown()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var currentBackground: AnyShapeStyle {
        let bg = OverlayBackground(rawValue: overlayBackground) ?? .dark
        return bg.previewGradient
    }

    private var videoServiceName: String {
        guard let url = event.videoLink else { return "Meeting" }
        return VideoLinkDetector.serviceName(for: url)
    }

    private var headerIcon: String {
        kind == .ending ? "hourglass.bottomhalf.filled" : "calendar.badge.clock"
    }

    private var dismissIcon: String {
        kind == .ending ? "checkmark" : "xmark"
    }

    private var dismissLabel: String {
        kind == .ending ? "Acknowledge" : "Dismiss"
    }

    private var secondaryTimeText: String {
        switch kind {
        case .start:
            return event.formattedStartTime
        case .ending:
            return "Ends at \(formattedEndTime)"
        }
    }

    private var formattedEndTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: event.endDate)
    }

    private func snoozeLabel(minutes: Int) -> String {
        minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    private func loadSnoozeOptions() {
        let stored = UserDefaults.standard.array(forKey: "snoozeOptions") as? [Int] ?? []
        snoozeOptions = stored.isEmpty ? [1, 2, 5, 10] : stored.sorted()
    }

    private func refreshAvailability() {
        switch kind {
        case .start:
            hasEnded = false
            availableSnoozeOptions = snoozeOptions
        case .ending:
            hasEnded = event.endDate.timeIntervalSinceNow <= 0
            // Offer the full configured snooze list, just like the start overlay.
            // The monitor caps any snooze that would run past the meeting's end.
            availableSnoozeOptions = snoozeOptions
        }
    }

    private var showQuickSnooze: Bool {
        guard !requireAction else { return false }
        switch kind {
        case .start:
            return !availableSnoozeOptions.isEmpty
        case .ending:
            return !hasEnded && !availableSnoozeOptions.isEmpty
        }
    }

    private var showSnoozeMenu: Bool {
        switch kind {
        case .start:
            return !availableSnoozeOptions.isEmpty
        case .ending:
            return !hasEnded && !availableSnoozeOptions.isEmpty
        }
    }

    private var showDismissButton: Bool {
        switch kind {
        case .start:
            return true
        case .ending:
            // Always show Acknowledge once snooze is no longer an option, so the
            // user can never be trapped in the overlay with no actionable button.
            return hasEnded || availableSnoozeOptions.isEmpty
        }
    }

    private func updateCountdown() {
        switch kind {
        case .start:
            let seconds = Int(event.startDate.timeIntervalSinceNow)
            if seconds <= 0 {
                countdown = "Starting now!"
            } else if seconds < 60 {
                countdown = "Starting in \(seconds) seconds"
            } else {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                if remainingSeconds == 0 {
                    countdown = "Starting in \(minutes) min"
                } else {
                    countdown = "Starting in \(minutes)m \(remainingSeconds)s"
                }
            }
        case .ending:
            let seconds = Int(event.endDate.timeIntervalSinceNow)
            if seconds <= 0 {
                let elapsed = -seconds
                if elapsed < 60 {
                    countdown = "Ended \(elapsed)s ago"
                } else {
                    countdown = "Ended \(elapsed / 60) min ago"
                }
            } else if seconds < 60 {
                countdown = "Ending in \(seconds) seconds"
            } else {
                let minutes = seconds / 60
                let remainingSeconds = seconds % 60
                if remainingSeconds == 0 {
                    countdown = "Ending in \(minutes) min"
                } else {
                    countdown = "Ending in \(minutes)m \(remainingSeconds)s"
                }
            }
        }
    }
}

private struct OverlayButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
