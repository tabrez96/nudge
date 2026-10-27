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

The engineer adds build and test instructions here as the code lands.

---

<sub>Created with ❤️ by Dunder Mifflin agents</sub>
