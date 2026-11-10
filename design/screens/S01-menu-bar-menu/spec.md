---
id: S01
name: Menu bar menu
purpose: Check that Nudge is working, see what's on now and next, join a call, and fix problems
size: 372x600
---

## Content and actions
- Status line: green dot + "Synced just now · <calendar>" or red dot + problem text.
- Now: shown only while a meeting is running (start ≤ now < end; all-day and declined meetings excluded), under a "Now" header above "Next meetings". Up to 3, earliest start first. Detail is "until <end time>" (e.g. "until 2:00 PM") in the normal muted style. Bold amber stays reserved for "in N min".
- Next meetings: up to 3 upcoming today on the chosen calendar; meeting due within 5 min shows "in N min" in bold amber. The header is left out when nothing is coming up.
- Meeting row (Now and Next): title on the left (one line, ellipsis), detail right-aligned. A meeting with a join link shows a small "Join" pill (11px semibold, white on accent #0B57D0, 5px radius) just left of the detail; the detail column stays right-aligned either way.
- Description: the start of the meeting's notes, under the title in 12px muted text, two lines at most, then ellipsis. Plain text only: HTML stripped, whitespace collapsed, and lines that are only a join link or conferencing boilerplate (e.g. "Join with Google Meet", dial-in numbers) removed. If nothing is left, no line is shown and the row stays one line.
- Join: a meeting row with a link is enabled; clicking anywhere on the row (or pressing Return on it) opens the link in the default browser/app and closes the menu. Rows without a link show no pill and are not clickable (same as before).
- Calendar submenu: pick which calendar to watch (checkmark on current).
- Test the alerts: runs the S03 banner and S02 screen with a fake meeting.
- Refresh now (⌘R), Quit (⌘Q).
- Menu bar icon: template bell, one colour, tinted by macOS for light and dark menu bars. While a problem exists: the same bell with a solid #B3261E dot at its top-right, separated from the bell by a thin clear ring. The bell itself never turns red.
## States
- Normal: screen.html (a running meeting under Now, three next meetings; one without a link or description).
- Running meeting, nothing after it today: states/now-only.html. Now section only; no "Next meetings" header and no empty text.
- Empty: states/empty.html. "No more meetings today. Enjoy the quiet." shows only when nothing is running and nothing else is coming up today. Calendar, Test the alerts and Refresh now stay in the menu.
- Error (network/calendar failure): states/error.html. Keeps alerting from last saved data, says so, offers Retry. Now and Join work from saved data too.
- No access / no account: states/no-access.html, links to the macOS permission prompt and Internet Accounts.
- Loading: status reads "Syncing…" with no dot colour change; list stays as is.
- Highlighted row (hover or arrow keys): standard blue selection; the pill inverts to white with blue text and the description turns white.
## Notes and open questions
- Problems are never shown as popups; only in this menu and the icon, so alerts are never interrupted.
- The whole row is the Join target rather than a separate button, so it works with the keyboard like any menu item and stays a single NSMenuItem (custom view for the pill and description).
- VoiceOver label per row: "<title>, <detail>. Join" when there is a link, "<title>, <detail>" otherwise; the description is read after it.
## Change log
- Initial design.
- Menu bar icon: problem state is the template bell plus a red #B3261E dot, replacing the red-tinted bell.badge.
- Added the "Now" section for running meetings; new state states/now-only.html; empty.html now keeps the Calendar/Test/Refresh rows and shows only when nothing is running or coming up (T-78; T-76 already matches).
- Added the Join pill and the two-line description to meeting rows, including in the error state (T-78, built in T-77).
