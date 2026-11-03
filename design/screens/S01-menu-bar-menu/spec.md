---
id: S01
name: Menu bar menu
purpose: Check that Nudge is working, see what's next, and fix problems
size: 372x340
---

## Content and actions
- Status line: green dot + "Synced just now · <calendar>" or red dot + problem text.
- Next meetings: up to 3 upcoming today on the chosen calendar; meeting due within 5 min shows "in N min" in bold amber.
- Calendar submenu: pick which calendar to watch (checkmark on current).
- Test the alerts: runs the S03 banner and S02 screen with a fake meeting.
- Refresh now (⌘R), Quit (⌘Q).
- Menu bar icon: template bell, one colour, tinted by macOS for light and dark menu bars. While a problem exists: the same bell with a solid #B3261E dot at its top-right, separated from the bell by a thin clear ring. The bell itself never turns red.
## States
- Normal: screen.html. Empty (no more meetings today): states/empty.html.
- Error (network/calendar failure): states/error.html. Keeps alerting from last saved data, says so, offers Retry.
- No access / no account: states/no-access.html, links to the macOS permission prompt and Internet Accounts.
- Loading: status reads "Syncing…" with no dot colour change; list stays as is.
## Notes and open questions
- Problems are never shown as popups; only in this menu and the icon, so alerts are never interrupted.
## Change log
- Initial design.
- Menu bar icon: problem state is the template bell plus a red #B3261E dot, replacing the red-tinted bell.badge.
