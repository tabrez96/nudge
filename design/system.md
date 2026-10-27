# Nudge — System design

## Overview
Nudge is a menu-bar-only macOS app (no Dock icon, no windows) that reads your Google
calendar through macOS EventKit. The Google account is added in System Settings → Internet
Accounts, so the app has no OAuth code or secrets. Every second the app checks the
cached meetings: at T-5 min it plays a sound and posts a banner (S03); at T-1 min it covers every
screen with a red countdown (S02). Every 60 s it re-reads the calendar; if that fails it keeps
alerting from the last good data and shows the problem in the menu (S01) and a red icon. All
timing, sync, status and display-text logic lives in a pure-Foundation library that builds and
tests on Linux; the thin AppKit/EventKit shell compiles only on macOS and is verified by hand.

## Stack
- **Swift 5.9+, SwiftPM**: native macOS per the brief; SwiftPM builds on Linux so QA can run the core tests without Xcode.
- **AppKit (`NSStatusItem`, `NSMenu`, borderless `NSWindow`)**: menu-bar apps and full-screen overlays are simplest and most controllable in AppKit; SwiftUI adds nothing here.
- **EventKit**: reads the Google calendar macOS already syncs; no OAuth, no network code, no credentials.
- **UserNotifications + NSSound**: system banner for S03; sound plays via `NSSound` separately so it still sounds if banners are denied or muted (S03 spec).
- **Storage**: `UserDefaults` for the chosen calendar ID only. Last good meetings are kept in memory: alerts only fire while the app runs, so persisting them buys nothing for the MVP.
- **Hosting/distribution**: none. `scripts/make-app.sh` builds an ad-hoc-signed `build/Nudge.app` on your Mac.
- **Tests**: XCTest via `swift test` on Linux for `NudgeCore`.

## Components
**`NudgeCore` (pure Foundation, tested on Linux)**
- `Meeting`: id (`calendarItemExternalIdentifier`), title, start, end, location?. `alertKey = id + start` so recurring instances and rescheduled meetings alert separately.
- `AlertEngine`: given meetings, `now`, and the set of already-fired keys, returns due `ScheduledAlert`s (`.fiveMinute` / `.oneMinute`). Rules:
  - five-minute fires when `start-5m ≤ now < start-1m`; one-minute when `start-1m ≤ now < start`.
  - Each (meeting, kind) fires at most once. Launching or waking late fires whatever window we are currently in; nothing fires for meetings already started.
  - Skips all-day, declined and cancelled events (filtered in the source, enforced again here via flags) — they aren't meetings the PM must attend.
  - If several meetings are due for S02 at once, the one starting soonest wins (S02 "new warning replaces the old").
- `CalendarSource` protocol: `authorization() -> CalendarAccess` (`.granted/.notDetermined/.denied`), `calendars() -> [CalendarInfo]`, `meetings(calendarID:from:to:) throws -> [Meeting]`. Errors: `CalendarSourceError.accessDenied / .calendarNotFound / .fetchFailed`.
- `CalendarChoice`: picks the saved calendar ID if it still exists, else the first Google calendar whose title looks like an email address (Google's primary), else the first calendar.
- `SyncCoordinator`: `refresh(now:)` asks the source for meetings from now-5 min to end of tomorrow. Success → replace meetings, status `.synced(at:)`. Failure → keep last good meetings, status `.error(kind, savedAt:)`. Access denied/no calendars → `.noAccess`. Sets `.syncing` while running.
- `SyncStatus` + `MenuModel`: pure builders for everything S01 displays — status line text, dot colour (green/red/none), icon state (normal/problem), up to 3 meeting rows for today with "in N min" (amber/bold flag when ≤5 min) or a time, section header ("Next meetings" / "Next meetings (last saved)"), and which action rows appear per state (normal, empty, error, no-access, notifications-denied warning).
- `AlertText`: S03 title/body ("<Meeting> in 5 minutes", "<time> · <location>"), S02 countdown ("1:00"…"0:01", then "Starting now"), time range, and the long-title rule (UI truncates at 2 lines).

**`Nudge` executable (macOS only, `#if os(macOS)`; on Linux `main.swift` just prints a message)**
- `AppDelegate`: `LSUIElement` app. Owns the `SyncCoordinator`, a 1 s `Timer` (in `.common` run-loop mode so it runs while the menu is open) that calls `AlertEngine`, and a 60 s refresh timer. Also refreshes on `EKEventStoreChanged` and on wake (`NSWorkspace.didWakeNotification`).
- `EventKitSource`: `CalendarSource` over `EKEventStore`; requests full access (`requestFullAccessToEvents` on macOS 14, `requestAccess(to:)` on 13); maps `EKEvent` → `Meeting`, dropping all-day, cancelled, and events where the current user's participant status is declined.
- `StatusMenuController` (S01): `NSStatusItem` with SF Symbol `bell` / `bell.badge` tinted #B3261E on problem; rebuilds the `NSMenu` from `MenuModel` in `menuNeedsUpdate`. Calendar submenu, Test the alerts, Refresh/Retry now (⌘R), Quit (⌘Q). No-access rows open the permission prompt and `x-apple.systempreferences:com.apple.Internet-Accounts-Settings.extension`.
- `Notifier` (S03): `UNUserNotificationCenter` banner + `NSSound(named: "Glass")`. Reports notification authorization to `MenuModel` for the warning row.
- `FullScreenAlertController` (S02): one borderless `NSWindow` per `NSScreen` at `.screenSaver` level, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, activates the app so the "Got it" button has focus; Return/Esc dismiss all windows; countdown updated by the 1 s tick; VoiceOver announcement once on open. A newer alert replaces the open one.

## Data model
```
Meeting        { id: String, title: String, start: Date, end: Date, location: String?,
                 isAllDay: Bool, isDeclined: Bool }      alertKey = "\(id)|\(start.timeIntervalSince1970)"
AlertKind      .fiveMinute | .oneMinute
ScheduledAlert { meeting: Meeting, kind: AlertKind }
CalendarInfo   { id: String, title: String, sourceTitle: String }
SyncStatus     .syncing | .synced(at: Date) | .error(CalendarSourceError, savedAt: Date?) | .noAccess
Persisted      UserDefaults "selectedCalendarID": String
In memory      lastGoodMeetings: [Meeting], firedKeys: Set<String> (pruned of meetings > 1 h old)
```

## Key flows
**1. First run (S01 no-access → normal)**
1. App launches, `EventKitSource.authorization()` is `.notDetermined` → status `.noAccess`, icon red, S01 shows no-access rows.
2. "Allow calendar access…" → system prompt. Granted → `CalendarChoice` picks a calendar → refresh → `.synced`, S01 normal.
3. No calendars (no Google account) → stays `.noAccess`; "Add Google account…" opens Internet Accounts. `EKEventStoreChanged` triggers refresh once the account appears.

**2. Alerts (S03 at T-5, S02 at T-1)**
1. Every second `AlertEngine.dueAlerts(meetings, now, firedKeys)`.
2. `.fiveMinute` → `Notifier` plays sound and posts the banner with `AlertText`; key marked fired.
3. `.oneMinute` → `FullScreenAlertController` shows a window on every screen; countdown ticks to "Starting now" and stays until "Got it"/Return/Esc, which closes all windows.

**3. Sync failure (S01 error)**
1. 60 s refresh throws (calendar removed, store error) → `SyncCoordinator` keeps `lastGoodMeetings`, status `.error(…, savedAt:)`.
2. Icon turns red; S01 shows "Can't reach your calendar. Alerting from data saved at 1:52 PM." and "Next meetings (last saved)"; alerts keep firing from the saved list.
3. "Retry now" (⌘R) or the next successful refresh → `.synced`, icon normal.
Note: EventKit reads macOS's local copy, so a plain network outage looks like "synced but stale" rather than an error; macOS catches up when the network returns. The error state covers what EventKit can report (access revoked, calendar gone, fetch failure).

## Testing approach
- Core (Linux, run by Dwight): `swift build && swift test`. Tests use a fake `CalendarSource` and injected `now`; no real clock or calendar.
  - `AlertEngineTests`: window boundaries (T-5:00, T-1:00, T-0), fire-once, late launch, past meetings, all-day/declined skipped, back-to-back ordering.
  - `SyncCoordinatorTests`: success, failure keeps last good data + savedAt, access denied → noAccess, recovery.
  - `CalendarChoiceTests`, `MenuModelTests` (every S01 state's text/rows/flags), `AlertTextTests` (S02 countdown, S03 title/body, no-location).
- macOS shell: Linux builds skip it (`#if os(macOS)`), so QA reviews that code by reading it. Verify on a Mac with `swift build` then `scripts/make-app.sh && open build/Nudge.app`, following the README checklist: first-run access, calendar picker, "Test the alerts" (S03 + S02 on all screens, Return/Esc/Got it), a real meeting created 6 minutes out, and toggling the Google account off in Internet Accounts for the error state.

## Open questions
None. (Snooze and video link stay out of MVP per the UX spec.)
