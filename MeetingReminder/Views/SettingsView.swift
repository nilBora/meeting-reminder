import EventKit
import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @AppStorage("reminderMinutes") private var reminderMinutes: Int = 5
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("requireAction") private var requireAction: Bool = false
    @AppStorage("overlayBackground") private var overlayBackground: String = "dark"
    @AppStorage("overlayOpacity") private var overlayOpacity: Double = 1.0
    @AppStorage("endReminderMinutes") private var endReminderMinutes: Int = 0
    @AppStorage(WorkingHoursEvents.enabledKey) private var workingHoursEnabled: Bool = false
    @AppStorage(WorkingHoursEvents.startMinutesKey) private var workingHoursStartMinutes: Int = WorkingHoursEvents.defaultStartMinutes
    @AppStorage(WorkingHoursEvents.endMinutesKey) private var workingHoursEndMinutes: Int = WorkingHoursEvents.defaultEndMinutes
    @AppStorage(WorkingHoursEvents.daysKey) private var workingHoursDaysMask: Int = WorkingHoursEvents.defaultDaysMask
    @AppStorage(FocusCountdownCoordinator.enabledKey) private var focusCountdownEnabled: Bool = false
    @AppStorage(FocusCountdownLayout.storageKey) private var focusCountdownLayout: String = FocusCountdownLayout.defaultLayout.rawValue
    @ObservedObject var calendarService: CalendarService
    @ObservedObject var meetingMonitor: MeetingMonitor

    @State private var launchAtLogin = false
    @State private var enabledCalendarIDs: Set<String> = []
    @State private var snoozeOptions: Set<Int> = [1, 2, 5, 10]

    private let snoozeOptionCandidates = [1, 2, 5, 10, 15]

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

            workingHoursTab
                .tabItem {
                    Label("Working Hours", systemImage: "clock")
                }

            focusTab
                .tabItem {
                    Label("Focus", systemImage: "timer")
                }

            calendarsTab
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }
        }
        .frame(width: 460, height: 420)
        .onAppear {
            loadSettings()
        }
    }

    private var generalTab: some View {
        Form {
            Section("Reminders") {
                Picker("Remind me before meetings:", selection: $reminderMinutes) {
                    Text("1 minute").tag(1)
                    Text("2 minutes").tag(2)
                    Text("5 minutes").tag(5)
                    Text("10 minutes").tag(10)
                }
                .pickerStyle(.menu)

                VStack(alignment: .leading, spacing: 4) {
                    Picker("Remind me when meeting is about to end:", selection: $endReminderMinutes) {
                        Text("Never").tag(0)
                        Text("1 minute").tag(1)
                        Text("2 minutes").tag(2)
                        Text("5 minutes").tag(5)
                        Text("10 minutes").tag(10)
                    }
                    .pickerStyle(.menu)
                    Text("Skipped when another meeting starts back-to-back.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Toggle("Play sound with reminder", isOn: $soundEnabled)
                Toggle("Require action (hide Snooze button)", isOn: $requireAction)
            }

            Section("Snooze options") {
                ForEach(snoozeOptionCandidates, id: \.self) { minutes in
                    Toggle(snoozeLabel(minutes: minutes), isOn: snoozeBinding(for: minutes))
                }
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section {
                Button {
                    meetingMonitor.previewOverlay()
                } label: {
                    Label("Preview overlay", systemImage: "play.circle")
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
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(bg.previewGradient)
                                .frame(height: 88)
                                .overlay(
                                    VStack(spacing: 2) {
                                        Text("Meeting")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("in 3 min")
                                            .font(.system(size: 9))
                                            .opacity(0.75)
                                    }
                                    .foregroundColor(.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Overlay opacity")
                    Spacer()
                    Text("\(Int(overlayOpacity * 100))%")
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $overlayOpacity, in: 0.3...1.0, step: 0.05)
            }

            Spacer()
        }
        .padding()
    }

    private var workingHoursTab: some View {
        Form {
            Section {
                Toggle("Enable working hours reminders", isOn: $workingHoursEnabled)
                    .onChange(of: workingHoursEnabled) { _ in calendarService.fetchEvents() }
                Text("Shows an overlay at the start and end of your work day, so you remember to begin and wrap up on time.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Hours") {
                DatePicker("Start time:",
                           selection: startTimeBinding,
                           displayedComponents: .hourAndMinute)
                    .disabled(!workingHoursEnabled)
                DatePicker("End time:",
                           selection: endTimeBinding,
                           displayedComponents: .hourAndMinute)
                    .disabled(!workingHoursEnabled)
            }

            Section("Days") {
                HStack(spacing: 8) {
                    ForEach(orderedWeekdayIndices, id: \.self) { weekdayIndex in
                        DayChip(label: weekdayShortSymbol(for: weekdayIndex),
                                isOn: dayBinding(weekdayIndex: weekdayIndex))
                    }
                    Spacer()
                }
                .disabled(!workingHoursEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var focusTab: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle("Show floating countdown to next meeting", isOn: $focusCountdownEnabled)
                .font(.system(size: 13, weight: .semibold))
            Text("A small always-on-top window that counts down to your next meeting. Drag it anywhere on screen.")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            Text("Layout")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                ForEach(FocusCountdownLayout.allCases) { layout in
                    Button {
                        focusCountdownLayout = layout.rawValue
                    } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.secondary.opacity(0.12))
                                .frame(height: 70)
                                .overlay(layoutPreview(layout))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(focusCountdownLayout == layout.rawValue ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                            Text(layout.displayName)
                                .font(.caption)
                                .foregroundColor(focusCountdownLayout == layout.rawValue ? .accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .disabled(!focusCountdownEnabled)

            Spacer()

            HStack {
                Spacer()
                Button("Reset window position") {
                    NotificationCenter.default.post(name: .focusCountdownResetPosition, object: nil)
                }
                .disabled(!focusCountdownEnabled)
            }
        }
        .padding()
    }

    @ViewBuilder
    private func layoutPreview(_ layout: FocusCountdownLayout) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            // Loop a 60-second countdown so previews show the digits ticking.
            let cycle: TimeInterval = 60
            let remaining = Int(cycle - context.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: cycle))
            let timeText = String(format: "%02d:%02d", remaining / 60, remaining % 60)
            let subtitle = "Standup"

            switch layout {
            case .modern:
                ModernDigitalView(time: timeText, subtitle: subtitle)
                    .padding(4)
            case .terminal:
                TerminalDigitalView(time: timeText, subtitle: subtitle)
                    .padding(4)
            case .flip:
                FlipDigitalView(time: timeText, subtitle: subtitle)
                    .padding(4)
            }
        }
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

        loadSnoozeOptions()
    }

    private func loadSnoozeOptions() {
        let stored = UserDefaults.standard.array(forKey: "snoozeOptions") as? [Int] ?? []
        snoozeOptions = stored.isEmpty ? [1, 2, 5, 10] : Set(stored)
    }

    private func saveSnoozeOptions() {
        UserDefaults.standard.set(Array(snoozeOptions).sorted(), forKey: "snoozeOptions")
    }

    private func snoozeBinding(for minutes: Int) -> Binding<Bool> {
        Binding(
            get: { snoozeOptions.contains(minutes) },
            set: { enabled in
                if enabled {
                    snoozeOptions.insert(minutes)
                } else {
                    guard snoozeOptions.count > 1 else { return }
                    snoozeOptions.remove(minutes)
                }
                saveSnoozeOptions()
            }
        )
    }

    private func snoozeLabel(minutes: Int) -> String {
        minutes == 1 ? "1 minute" : "\(minutes) minutes"
    }

    private var orderedWeekdayIndices: [Int] {
        let firstWeekday = Calendar.current.firstWeekday // 1=Sun
        return (0..<7).map { (firstWeekday - 1 + $0) % 7 }
    }

    private func weekdayShortSymbol(for weekdayIndex: Int) -> String {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return symbols[weekdayIndex]
    }

    private func dayBinding(weekdayIndex: Int) -> Binding<Bool> {
        let bit = 1 << weekdayIndex
        return Binding(
            get: { (workingHoursDaysMask & bit) != 0 },
            set: { enabled in
                if enabled {
                    workingHoursDaysMask |= bit
                } else {
                    workingHoursDaysMask &= ~bit
                }
                calendarService.fetchEvents()
            }
        )
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: workingHoursStartMinutes) },
            set: { newDate in
                workingHoursStartMinutes = Self.minutes(fromDate: newDate)
                calendarService.fetchEvents()
            }
        )
    }

    private var endTimeBinding: Binding<Date> {
        Binding(
            get: { Self.date(fromMinutes: workingHoursEndMinutes) },
            set: { newDate in
                workingHoursEndMinutes = Self.minutes(fromDate: newDate)
                calendarService.fetchEvents()
            }
        )
    }

    private static func date(fromMinutes minutes: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: minutes / 60,
                             minute: minutes % 60,
                             second: 0,
                             of: Date()) ?? Date()
    }

    private static func minutes(fromDate date: Date) -> Int {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
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

private struct DayChip: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isOn ? Color.accentColor : Color.secondary.opacity(0.15))
                )
                .foregroundColor(isOn ? .white : .secondary)
        }
        .buttonStyle(.plain)
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
