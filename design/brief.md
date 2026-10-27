# Build macOS app: Google Calendar meeting alerts with full-page warning

**Problem:** People miss meetings even with Google Calendar alerts enabled because the default small banner is easy to miss.

**Solution:** Native macOS app that syncs with Google Calendar (primary calendar) and fires alerts before meetings:
- 5 minutes before: audio alert + banner notification
- 1 minute before: full-page modal warning
- Runs in background, fires only when app is running

**Tech:** Native Swift macOS app, Google Calendar API for event sync, system notifications + custom modal UI.

**Definition of Done:** App launches, syncs calendar, fires both alerts at correct times, handles network errors gracefully.

## Technical plan from the architect (context only: design the UX, not the code)
# Plan: Build macOS app: Google Calendar meeting alerts with full-page warning

## Goal
Nudge is a menu-bar macOS app that reads your Google calendar through macOS
EventKit. You add the Google account in System Settings → Internet Accounts, so the app
needs no OAuth credentials. For each upcoming meeting on the chosen
calendar, the app:
- plays a sound and posts a banner notification 5 minutes before the start;
- covers every screen with a full-screen warning 1 minute before the start.

Alerts fire only while the app is running. If calendar data can't be loaded, the app keeps
alerting from the last good data and shows the problem in its menu.

All timing, sync and error logic lives in a pure-Foundation library, `NudgeCore`, that
builds and tests on Linux. The AppKit/EventKit shell compiles only on macOS. The shell is tested by hand on a Mac.

## Files
- `Package.swift`: create. SwiftPM package with three targets: library `NudgeCore`, executable `Nudge`, and test target `NudgeCoreTests`.
- `Sources/NudgeCore/Meeting.swift`: create. `Meeting`, `AlertKind`, `ScheduledAlert` types.
- `Sources/NudgeCore/AlertEngine.swift`: create. Decides which alerts are due at a given `now`.
- `Sources/NudgeCore/CalendarSource.swift`: create. `CalendarSource` protocol, `CalendarInfo`, `CalendarSourceError`.
- `Sources/NudgeCore/SyncStatus.swift`: create. Sync status enum plus the menu text for it.
- `Sources/NudgeCore/SyncCoordinator.swift`: create. Refreshes meetings from a `CalendarSource`, keeps the last good data when a refresh fails, and updates the status.
- `Sources/NudgeCore/CalendarChoice.swift`: create. Picks which calendar to use.
- `Sources/Nudge/main.swift`: create. App entry point. On Linux it only prints a message.
- `Sources/Nudge/AppDelegate.swift`: create (macOS only). Wires everything together, runs the 1-second tick and the 60-second refresh.
- `Sources/Nudge/EventKitSource.swift`: create (macOS only). `CalendarSource` implementation backed by `EKEventStore`.
- `Sources/Nudge/StatusMenuController.swift`: create (macOS only). The menu bar item and its menu.
- `Sources/Nudge/Notifier.swift`: create (macOS only). The 5-minute sound and banner.
- `Sources/Nudge/FullScreenAlertController.swift`: create (macOS only). The 1-minute full-screen windows.
- `Tests/NudgeCoreTests/AlertEngineTests.swift`: create.
- `Tests/NudgeCoreTests/SyncCoordinatorTests.swift`: create.
- `Tests/NudgeCoreTests/SyncStatusTests.swift`: create.
- `Tests/NudgeCoreTests/CalendarChoiceTests.swift`: create.
- `Support/Info.plist`: create. Bundle id, `LSUIElement`, calendar usage strings.
- `scripts/make-app.sh`: create (executable). Builds `build/Nudge.app` on a Mac.
- `.gitignore`: modify. Add `.build/` and `build/`.
- `README.md`: modify. Explain what the app does, Mac setup, how to build, test and manually verify.

## Steps

### 0. Toolchain (Linux sandbox)
1. Run `swift --version`. If it prints Swift 5.9 or newer, go to step 1.
2. If Swift is missing, install it with swiftly (from swift.org):
   ```
   cd /tmp && curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz"
   tar zxf "swiftly-$(uname -m).tar.gz" && ./swiftly init --quiet-shell-followup -y
   . "${SWIFTLY_HOME_DIR:-$HOME/.local/share/swiftly}/env.sh"
   swift --version
   ```
   If that install fails (no network, no permissions), still write all the code. Then report in
   your result message that `swift build` and `swift test` were not run. **Do not** claim tests
   passed.

### 1. `Package.swift`
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Nudge",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "Nudge", targets: ["Nudge"])],
    targets: [
        .target(name: "Meet

[... plan truncated; the full plan is on the ticket]
