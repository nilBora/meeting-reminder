# Meeting Reminder for Mac

Native macOS menu bar app (Swift + SwiftUI) that reads the user's calendar and displays a full-screen blocking overlay before meetings with one-click video conference join.

## Build & Run

```bash
# Build (requires Xcode)
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project MeetingReminder.xcodeproj \
  -scheme MeetingReminder \
  -configuration Debug build

# Open in Xcode
open MeetingReminder.xcodeproj
```

Target: macOS 13+ (Ventura). Swift 5. No external dependencies.

## Architecture

```
MeetingReminder/
├── MeetingReminderApp.swift        # @main entry, MenuBarExtra (.window style), OverlayCoordinator
├── Models/
│   └── MeetingEvent.swift          # Wraps EKEvent, computed helpers (countdown, formatting)
├── Services/
│   ├── CalendarService.swift       # EventKit: access, fetch, filter, auto-refresh (5 min + EKEventStoreChanged)
│   ├── MeetingMonitor.swift        # 30s timer, triggers overlay when event ≤ N min away, snooze/dismiss
│   └── VideoLinkDetector.swift     # Regex detection: Zoom, Meet, Teams, Webex, Slack in notes/URL/location
├── Views/
│   ├── MenuBarView.swift           # Window-style popover: event list, preferences button, quit
│   ├── OverlayWindow.swift         # NSPanel at .screenSaver level, covers all screens
│   ├── OverlayView.swift           # Full-screen SwiftUI: title, countdown, Join/Snooze/Dismiss buttons
│   └── SettingsView.swift          # Tabs: General, Appearance (overlay backgrounds), Calendars
├── Resources/Assets.xcassets       # App icon (generated via generate_icon.py)
├── Info.plist                      # LSUIElement=true (no Dock icon), calendar usage descriptions
└── MeetingReminder.entitlements    # App sandbox + calendar access
```

## Key Technical Decisions

- **MenuBarExtra with `.window` style** — avoids the known SwiftUI NSMenu item tracking bug ("rep returned item view with wrong item") that occurs with `.menu` style when content changes dynamically
- **NSPanel at `.screenSaver` level** — overlay appears above full-screen apps and all spaces
- **LSUIElement = true** — runs as background menu bar agent, no Dock icon
- **`@Environment(\.openSettings)`** (macOS 14+) — required to open Settings; the `sendAction(showSettingsWindow:)` selector is blocked on macOS 14+. Wrapped in `PreferencesButton14` with `@available` check, falls back to `showPreferencesWindow:` on macOS 13
- **`NSApp.activate(ignoringOtherApps: true)` + `orderFrontRegardless()`** — needed after opening Settings because LSUIElement apps don't get focus automatically
- **OverlayBackground enum** — stores background choice as string in `@AppStorage("overlayBackground")`, returns `AnyShapeStyle` for use in overlay

## Settings (UserDefaults keys)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `reminderMinutes` | Int | 5 | Minutes before meeting to show overlay |
| `soundEnabled` | Bool | true | Play alert sound with overlay |
| `overlayBackground` | String | "dark" | Background style (dark/blue/purple/gradient/red/green/nightOcean/electric/cyber) |
| `enabledCalendarIDs` | [String] | [] | Calendar IDs to monitor (empty = all) |

## Icon Generation

```bash
python3 generate_icon.py
```

Requires `Pillow`. Generates all 10 sizes into `AppIcon.appiconset/`.
