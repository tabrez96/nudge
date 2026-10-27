# Nudge

A Mac menu bar app that warns you before Google Calendar meetings

Problem: People miss meetings even with Google Calendar alerts enabled because the default small banner is easy to miss. Solution: Native macOS app that syncs with Google Calendar (primary calendar) and fires alerts before meetings: 5 minutes before: audio alert + banner notification 1 minute before: full-page modal warning Runs in background, fires only when app is running Tech: Native Swift macOS app, Google Calendar API for event sync, system notifications + custom modal UI.

## Where things are
- `design/` is the design library: `brief.md`, `ux.md`, and `screens/S01-name/` (`screen.png` + `spec.md`, plus
  `states/*.png` for empty, error and other states). Screens have permanent IDs (S01, S02, ...). Tickets name the
  screens they build by ID. **Read the spec and look at the screenshot of every screen you build**; `ux.md` has the
  colors, type and spacing. Don't edit `design/`; the designer owns it.
- Design canvas (private and behind a login, so you can't open it; it's where the design gets reviewed): <!-- canvas -->https://claude.ai/artifact/EFWU5wjM58FRAEUbhdQxdb<!-- /canvas -->
- Source code lives outside `design/`. Put it where the stack below says.

## Stack
<!-- stack -->
- **Swift 5.9+, SwiftPM**: native macOS per the brief; SwiftPM builds on Linux so QA can run the core tests without Xcode.
- **AppKit (`NSStatusItem`, `NSMenu`, borderless `NSWindow`)**: menu-bar apps and full-screen overlays are simplest and most controllable in AppKit; SwiftUI adds nothing here.
- **EventKit**: reads the Google calendar macOS already syncs; no OAuth, no network code, no credentials.
- **UserNotifications + NSSound**: system banner for S03; sound plays via `NSSound` separately so it still sounds if banners are denied or muted (S03 spec).
- **Storage**: `UserDefaults` for the chosen calendar ID only. Last good meetings are kept in memory: alerts only fire while the app runs, so persisting them buys nothing for the MVP.
- **Hosting/distribution**: none. `scripts/make-app.sh` builds an ad-hoc-signed `build/Nudge.app` on your Mac.
- **Tests**: XCTest via `swift test` on Linux for `NudgeCore`.
<!-- /stack -->

## How we work here
- Two long-lived branches: `develop` is where the work lands (every ticket's PR goes there); `master` is the
  release branch and only moves when the maintainer launches a release. Never commit to `master`.
- One ticket at a time, on its own branch (`dmi/t-<n>`), cut from `develop`. Small, focused changes.
- Each ticket becomes a pull request into `develop` that the maintainer reviews. Keep the diff small enough to read in one sitting.
- Prefer boring, proven tools. Don't add a dependency unless the ticket needs it.
- Write tests for what you build, and run them before you say you're done. Document the build and test commands in the README under "Development".
- Never commit secrets, tokens or personal data. Don't put real credentials in examples.
- If the ticket is unclear or the design is missing something, ask the architect or designer instead of guessing.
