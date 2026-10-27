---
id: S02
name: Full-screen warning
purpose: Make it impossible to miss that a meeting starts in one minute
size: 1440x900
---

## Content and actions
- Covers every connected screen at 1 minute before start. Red background (#7A0F0A), white text.
- "Starting in" + live countdown (1:00 → 0:00), meeting title, time range, location if any.
- "Got it" button (focused by default); Return or Esc also dismisses. Dismiss closes on all screens.
- At 0:00 the countdown reads "Starting now" and the screen stays until dismissed.
## States
- Single main state (screen.html). No location: line shows time range only. Very long title: wraps, max 2 lines, then ellipsis.
- Back-to-back meetings: the new warning replaces the old one.
## Notes and open questions
- Countdown is announced to VoiceOver once at open, not every second.
## Change log
- Initial design.
