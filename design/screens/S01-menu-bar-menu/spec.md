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
- Menu bar icon: bell; turns red with a dot while a problem exists.
## States
- Normal: screen.html. Empty (no more meetings today): states/empty.html.
- Error (network/calendar failure): states/error.html. Keeps alerting from last saved data, says so, offers Retry.
- No access / no account: states/no-access.html, links to the macOS permission prompt and Internet Accounts.
- Loading: status reads "Syncing…" with no dot colour change; list stays as is.
## Notes and open questions
- Problems are never shown as popups; only in this menu and the icon, so alerts are never interrupted.
## Change log
- Initial design.
