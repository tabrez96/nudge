<!-- about -->
# Nudge

**A Mac menu bar app that warns you before Google Calendar meetings**

Status: In development

## What it does

Nudge is a menu-bar-only macOS app (no Dock icon, no windows) that reads your Google calendar through macOS EventKit. The Google account is added in System Settings → Internet Accounts, so the app has no OAuth code or secrets. Every second the app checks the cached meetings: at T-5 min it plays a sound and posts a banner (S03); at T-1 min it covers every screen with a red countdown (S02). Every 60 s it re-reads the calendar; if that fails it keeps alerting from the last good data and shows the problem in the menu (S01) and a red icon. All timing, sync, status and display-text logic lives in a pure-Foundation library that builds and tests on Linux; the thin AppKit/EventKit shell compiles only on macOS and is verified by hand.

## Screens

### S01 · Menu bar menu

Check that Nudge is working, see what's next, and fix problems

![S01 Menu bar menu](design/screens/S01-menu-bar-menu/screen.png)

### S02 · Full-screen warning

Make it impossible to miss that a meeting starts in one minute

![S02 Full-screen warning](design/screens/S02-full-screen-warning/screen.png)

### S03 · Five-minute banner

Early heads-up with sound, 5 minutes before a meeting

![S03 Five-minute banner](design/screens/S03-five-minute-banner/screen.png)

## Built with

- **Swift 5.9+, SwiftPM**: native macOS per the brief; SwiftPM builds on Linux so QA can run the core tests without Xcode.
- **AppKit (`NSStatusItem`, `NSMenu`, borderless `NSWindow`)**: menu-bar apps and full-screen overlays are simplest and most controllable in AppKit; SwiftUI adds nothing here.
- **EventKit**: reads the Google calendar macOS already syncs; no OAuth, no network code, no credentials.
- **UserNotifications + NSSound**: system banner for S03; sound plays via `NSSound` separately so it still sounds if banners are denied or muted (S03 spec).
- **Storage**: `UserDefaults` for the chosen calendar ID only. Last good meetings are kept in memory: alerts only fire while the app runs, so persisting them buys nothing for the MVP.
- **Hosting/distribution**: none. `scripts/make-app.sh` builds an ad-hoc-signed `build/Nudge.app` on your Mac.
- **Tests**: XCTest via `swift test` on Linux for `NudgeCore`.
<!-- /about -->

## Development

Requires Swift 5.9 or newer. On macOS, install Xcode 15+ (or the command line tools). On Linux, install
Swift with [swiftly](https://www.swift.org/install/linux/); only the `NudgeCore` library and its tests
are meaningful there.

```sh
swift build        # build everything
swift test         # run the NudgeCore tests (works on Linux and macOS)
swift run Nudge    # macOS: starts the menu bar app; Linux: prints a "macOS only" message
```

Layout:
- `Sources/NudgeCore` — pure-Foundation logic (timing, sync, display text), tested on Linux.
- `Sources/Nudge` — the macOS app shell (AppKit/EventKit), compiled only on macOS.
- `Tests/NudgeCoreTests` — XCTest tests for `NudgeCore`.

### Mac setup

1. Add your Google account in System Settings → Internet Accounts and turn on Calendars. Wait for its calendars to show up in the Calendar app. Nudge reads them through macOS and never asks for a Google password.
2. On first launch, macOS asks for calendar access. If you said no, turn it on in System Settings → Privacy & Security → Calendars.
3. On first launch, macOS also asks to allow notifications. If you said no, Nudge still plays its sound and the menu says notifications are off; turn them on in System Settings → Notifications → Nudge (alert style Banners or Alerts).

### Build the app

```sh
scripts/make-app.sh
open build/Nudge.app
```

The script builds in release mode, copies the binary and `Support/Info.plist` into `build/Nudge.app`, and ad-hoc signs the bundle (`codesign --sign -`), so it only runs on the Mac that built it. The app has no Dock icon and lives in the menu bar. Click the bell in the menu bar to see sync status and your next meetings. Five minutes before a meeting Nudge plays the Glass sound and posts a banner. One minute before, a red full-screen warning with a countdown covers every screen, including full-screen apps and other Spaces; Got it, Return or Esc closes it everywhere. Alerts are also logged to Console.app (search for "Nudge alert"). Run the bundled app for banners: `swift run Nudge` has no app bundle, so it plays the sound only.

### Check the full-screen warning by hand

1. With two displays connected and an app in full screen on one of them, create a meeting starting in 3 minutes with a location, and another 3 minutes later with no location.
2. At one minute before the first: every screen turns red, "Got it" has a yellow ring, the countdown runs 1:00 → 0:01, then shows "Starting now" (the "STARTING IN" line disappears) and stays.
3. Press Esc: all screens close. Repeat with Return and with clicking Got it on the second display.
4. Leave the first warning open: when the second fires it replaces it and shows only the time range.
5. With VoiceOver on (⌘F5), the warning is read once when it opens, not every second.

---

<sub>Created with ❤️ by Dunder Mifflin agents</sub>
