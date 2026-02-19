# Changelog

All notable changes to Meeting Reminder will be documented in this file.

## [1.0.1] - 2026-02-19

### Fixed
- Recurring events not triggering overlay on subsequent days — EventKit returns the same `eventIdentifier` for every occurrence, so the event was incorrectly marked as already shown. Event ID now includes the start date to uniquely identify each occurrence
- Daily cleanup of shown/snoozed event sets to prevent stale state across days

### Improved
- Time until meeting now displays in hours and minutes (e.g. "1 h 30 min") instead of raw minutes for events 60+ minutes away

## [1.0.0] - 2026-02-17

### Initial Release

**Core Features**
- Native macOS menu bar app — runs as a background agent (no Dock icon)
- Reads events from the system calendar via EventKit
- Full-screen blocking overlay appears N minutes before a meeting starts
- One-click "Join" button to open video conference links directly from the overlay
- Snooze and Dismiss controls on the overlay
- Live countdown timer to meeting start

**Video Link Detection**
- Automatic detection of video conference URLs in event notes, location, and URL fields
- Supported services: Zoom, Google Meet, Microsoft Teams, Webex, Slack Huddles

**Menu Bar**
- Window-style popover showing upcoming events for the day
- Quick access to Preferences and Quit

**Settings**
- Configurable reminder time (1, 2, 5, or 10 minutes before meeting)
- Alert sound toggle
- 9 overlay background themes: Dark, Blue, Purple, Sunset, Red, Green, Night Ocean, Electric, Cyber
- Calendar selection — choose which calendars to monitor
- Launch at login support (via SMAppService)

**Technical**
- macOS 13+ (Ventura) support
- Auto-refresh: events update every 5 minutes and on `EKEventStoreChanged` notifications
- Overlay uses `NSPanel` at `.screenSaver` window level — appears above full-screen apps
- App Sandbox with calendar entitlement
