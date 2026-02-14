import SwiftUI

struct OverlayView: View {
    let event: MeetingEvent
    let onDismiss: () -> Void
    let onSnooze: () -> Void
    let onJoin: () -> Void

    @State private var appeared = false
    @State private var countdown: String = ""
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Background blur/dim
            Color.black.opacity(0.85)

            VStack(spacing: 24) {
                Spacer()

                // Calendar icon
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))

                // Meeting title
                Text(event.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Time info
                Text(countdown)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))

                Text(event.formattedStartTime)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.6))

                // Calendar name
                Text(event.calendar)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.top, -8)

                Spacer()

                // Action buttons
                HStack(spacing: 20) {
                    if event.videoLink != nil {
                        Button(action: onJoin) {
                            HStack(spacing: 8) {
                                Image(systemName: "video.fill")
                                Text("Join \(videoServiceName)")
                            }
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.return, modifiers: [])
                    }

                    Button(action: onSnooze) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("Snooze 1 min")
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)

                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                            Text("Dismiss")
                        }
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }

                Spacer()
                    .frame(height: 80)
            }
            .scaleEffect(appeared ? 1.0 : 0.9)
            .opacity(appeared ? 1.0 : 0.0)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                appeared = true
            }
            updateCountdown()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    updateCountdown()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private var videoServiceName: String {
        guard let url = event.videoLink else { return "Meeting" }
        return VideoLinkDetector.serviceName(for: url)
    }

    private func updateCountdown() {
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
    }
}
