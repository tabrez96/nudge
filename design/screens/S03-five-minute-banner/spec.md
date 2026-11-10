---
id: S03
name: Five-minute banner
purpose: Early heads-up with sound, 5 minutes before a meeting
size: 480x160
---

## Content and actions
- Standard macOS notification: title "<Meeting> in 5 minutes", subtitle "<time> · <location>", body the start of the meeting's description (same cleaning as S01; macOS shows about two lines). No description: no body. Plays alert sound.
- Join: a notification action button "Join", only when the meeting has a join link. It opens the link in the default browser/app. Clicking the banner itself does nothing beyond dismissing.
## States
- With join link and description: screen.html.
- No join link, no description: states/no-link.html (no button, no body).
- No location: subtitle shows time only. Notifications denied: S01 shows a warning (see no-access) and the sound still plays.
## Notes and open questions
- Uses the system look, so Focus modes may mute it; the S02 screen is the backstop.
- The Join button uses a notification category with one action; macOS decides whether it shows on the banner or on hover, so the mockup shows it inline.
## Change log
- Initial design.
- Added the Join action and the description body; time and location move to the subtitle; new state states/no-link.html (T-78, built in T-77).
