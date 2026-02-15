import EventKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderMinutes") private var reminderMinutes: Int = 5
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("overlayBackground") private var overlayBackground: String = "dark"
    @ObservedObject var calendarService: CalendarService

    @State private var launchAtLogin = false
    @State private var enabledCalendarIDs: Set<String> = []

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            appearanceTab
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            calendarsTab
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }
        }
        .frame(width: 460, height: 380)
        .onAppear {
            loadSettings()
        }
    }

    private var generalTab: some View {
        Form {
            Section {
                Picker("Remind me before meetings:", selection: $reminderMinutes) {
                    Text("1 minute").tag(1)
                    Text("2 minutes").tag(2)
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                }
                .pickerStyle(.menu)
            }

            Section {
                Toggle("Play sound with reminder", isOn: $soundEnabled)
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section {
                HStack {
                    Text("Calendar access:")
                    Spacer()
                    if calendarService.authorizationStatus == .authorized {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Button("Request Access") {
                            Task {
                                await calendarService.requestAccess()
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var appearanceTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overlay Background")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                ForEach(OverlayBackground.allCases) { bg in
                    Button {
                        overlayBackground = bg.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(bg.previewGradient)
                                .frame(height: 70)
                                .overlay(
                                    Text("Aa")
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(overlayBackground == bg.rawValue ? Color.accentColor : Color.clear, lineWidth: 3)
                                )

                            Text(bg.displayName)
                                .font(.caption)
                                .foregroundColor(overlayBackground == bg.rawValue ? .accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()
        }
        .padding()
    }

    private var calendarsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select which calendars to monitor:")
                .font(.headline)

            if calendarService.availableCalendars.isEmpty {
                Text("No calendars available. Grant calendar access first.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                        Toggle(isOn: binding(for: calendar.calendarIdentifier)) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(cgColor: calendar.cgColor))
                                    .frame(width: 10, height: 10)
                                Text(calendar.title)
                            }
                        }
                    }
                }
            }

            Text("If none selected, all calendars are monitored.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private func binding(for calendarID: String) -> Binding<Bool> {
        Binding(
            get: { enabledCalendarIDs.contains(calendarID) },
            set: { enabled in
                if enabled {
                    enabledCalendarIDs.insert(calendarID)
                } else {
                    enabledCalendarIDs.remove(calendarID)
                }
                saveCalendarSelection()
            }
        )
    }

    private func loadSettings() {
        let ids = UserDefaults.standard.stringArray(forKey: "enabledCalendarIDs") ?? []
        enabledCalendarIDs = Set(ids)

        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func saveCalendarSelection() {
        UserDefaults.standard.set(Array(enabledCalendarIDs), forKey: "enabledCalendarIDs")
        calendarService.fetchEvents()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }
}

enum OverlayBackground: String, CaseIterable, Identifiable {
    case dark
    case blue
    case purple
    case gradient
    case red
    case green
    case nightOcean
    case electric
    case cyber

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dark: return "Dark"
        case .blue: return "Blue"
        case .purple: return "Purple"
        case .gradient: return "Sunset"
        case .red: return "Red"
        case .green: return "Green"
        case .nightOcean: return "Night Ocean"
        case .electric: return "Electric"
        case .cyber: return "Cyber"
        }
    }

    var previewGradient: AnyShapeStyle {
        switch self {
        case .dark:
            return AnyShapeStyle(Color.black.opacity(0.85))
        case .blue:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.3).opacity(0.88),
                                        Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .purple:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.2, green: 0.05, blue: 0.3).opacity(0.88),
                                        Color(red: 0.4, green: 0.1, blue: 0.5).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .gradient:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.2).opacity(0.88),
                                        Color(red: 0.4, green: 0.1, blue: 0.2).opacity(0.88),
                                        Color(red: 0.6, green: 0.2, blue: 0.1).opacity(0.88)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        case .red:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.3, green: 0.02, blue: 0.02).opacity(0.88),
                                        Color(red: 0.5, green: 0.05, blue: 0.05).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .green:
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.02, green: 0.15, blue: 0.1).opacity(0.88),
                                        Color(red: 0.05, green: 0.3, blue: 0.15).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .nightOcean:
            // #0a0e14 → #111821 → #1b2632 with cyan accent glow
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.039, green: 0.055, blue: 0.078).opacity(0.92),
                                        Color(red: 0.067, green: 0.094, blue: 0.129).opacity(0.90),
                                        Color(red: 0.106, green: 0.149, blue: 0.196).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .electric:
            // #0f172a → #1e293b → #334155 with neon blue tint
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.059, green: 0.09, blue: 0.165).opacity(0.92),
                                        Color(red: 0.118, green: 0.161, blue: 0.231).opacity(0.90),
                                        Color(red: 0.2, green: 0.255, blue: 0.333).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        case .cyber:
            // #050505 → #0d1117 → #161b22 with subtle blue glow
            return AnyShapeStyle(
                LinearGradient(colors: [Color(red: 0.02, green: 0.02, blue: 0.02).opacity(0.93),
                                        Color(red: 0.051, green: 0.067, blue: 0.09).opacity(0.91),
                                        Color(red: 0.086, green: 0.106, blue: 0.133).opacity(0.88)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }
}
