---
id: S02
name: Full-screen warning
purpose: Make it impossible to miss that a meeting starts in one minute, and get into it in one click
size: 1440x900
---

## Content and actions
- Covers every connected screen at 1 minute before start. Red background (#7A0F0A), white text.
- "Starting in" + live countdown (1:00 → 0:00), meeting title, time range, location if any.
- Description: the start of the meeting's notes under the time line, 24px white at 90% opacity, max 760px wide, two lines at most, then ellipsis. Same cleaning as S01 (plain text, join-link and conferencing boilerplate removed). Nothing is shown when there is none.
- Buttons, side by side, centred: "Join" (white fill, red text) when the meeting has a join link, then "Got it" (white outline on red). Without a link only "Got it" shows, in the white-fill style.
- Join opens the link in the default browser/app and dismisses the warning on all screens.
- "Got it" is focused by default; Return or Esc dismisses. Return never joins, so a keystroke typed as the warning appears can't open a call by accident. Tab moves to Join; Space activates the focused button. Dismiss closes on all screens.
- At 0:00 the countdown reads "Starting now" and the screen stays until dismissed or joined.
## States
- With join link and description: screen.html.
- No join link, no description: states/no-link.html (only "Got it", no description line).
- No location: line shows time range only. Very long title: wraps, max 2 lines, then ellipsis.
- Back-to-back meetings: the new warning replaces the old one.
## Notes and open questions
- Countdown is announced to VoiceOver once at open, not every second. The announcement adds "Join available" when there is a link.
- Join gets the filled style because it is the action most people want; focus stays on "Got it" for safety (see above).
## Change log
- Initial design.
- Added the Join button and the two-line description; new state states/no-link.html (T-78, built in T-77).
