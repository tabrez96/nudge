---
id: S03
name: Five-minute banner
purpose: Early heads-up with sound, 5 minutes before a meeting
size: 480x160
---

## Content and actions
- Standard macOS notification: title "<Meeting> in 5 minutes", body "<time> · <location>". Plays alert sound. Clicking it does nothing beyond dismissing.
## States
- Single state. No location: body shows time only. Notifications denied: S01 shows a warning (see no-access) and the sound still plays.
## Notes and open questions
- Uses the system look, so Focus modes may mute it; the S02 screen is the backstop.
## Change log
- Initial design.
