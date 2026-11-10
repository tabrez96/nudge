# Nudge: UX spec
## Users and primary jobs
One user: a busy person who misses meetings despite Google Calendar banners. Jobs: (1) get a loud early heads-up, (2) get an unmissable final warning and get into the call in one click, (3) trust the app is running and in sync.
## Information architecture
No windows. Menu bar only: S01 Menu bar menu; alerts S03 Five-minute banner and S02 Full-screen warning.
## Key flows
1. First run: S01 shows no-access state → user allows calendar access / adds Google account → S01 normal.
2. T-5 min: S03 banner + sound → "Join" (if the meeting has a link) opens the call.
3. T-1 min: S02 covers all screens → "Join" opens the call and dismisses, or "Got it" / Return / Esc dismisses.
4. Any time: S01 shows the running meeting under "Now" and today's next ones → click a row with a "Join" pill to open the call.
5. Sync failure: S01 icon turns red; menu explains and keeps alerting from saved data → Retry.
## Design system
- Colours: alert red #7A0F0A, error red #B3261E, ok green #1E7F3C, amber #A35200, text #1D1D1F, muted #5F6368, menu bg #F6F6F7, accent #0B57D0. Brand (logo and app icon only): gradient #EF5A47 → #C42F25, calendar header #9E1F17.
- Type: system font (SF). Menu 13px; banner title 13px semibold; full-screen: 96px title, 200px countdown, 24–28px secondary.
- Spacing: 6/10/14px in menus; 40px padding full-screen.
- Components: menu row, status line, primary button (white on red), secondary button (white outline on red), Join pill (S01: 11px semibold, white on #0B57D0, 5px radius).
- Join link: the meeting's URL field first, then the first link in its location or notes, preferring Google Meet (meet.google.com), Zoom (zoom.us), Teams (teams.microsoft.com), else any https link. No link: no Join anywhere.
- Description: the start of the meeting's notes as plain text (HTML stripped, whitespace collapsed, join-link and dial-in boilerplate removed), two lines at most, then ellipsis; nothing shown when empty. Muted 12px in S01, 24px at 90% white in S02, notification body in S03.
- Tone: short, calm, plain. No exclamation marks.
- Logo: a small calendar page (white sheet, deep-red header #9E1F17, two binder rings, one red meeting block) tilted to the left on a warm coral-to-red gradient tile (#EF5A47 top-left to #C42F25 bottom-right), with two short white motion arcs at its right edge, as if it has just been tapped. It says "your calendar, nudging you": Nudge gives your meetings a little shake before they start. The gradient is deliberately lighter and warmer than the alert red #7A0F0A so the icon sits comfortably in the Dock; the deep alert red stays reserved for S02. At 16px the arcs fade and the tilted white page with its red top still reads as a calendar. `brand/mark.svg` is the square master for the app icon (Finder, Dock, installer); `brand/logo.svg` is the mark beside "Nudge" in text #1D1D1F (use on light backgrounds; on dark, set the word in white). The tile carries its own background, so the mark works on light and dark without a variant. Keep clear space of at least a quarter of the mark's width around it. The S01 menu bar icon stays the bell; the mark is not used in the menu bar.
## Accessibility
Contrast ≥ 4.5:1 (white on #7A0F0A ≈ 11:1). Everything is keyboard operable; Return/Esc dismiss S02 and never join; visible focus ring; dismiss button focused on open; VoiceOver labels on all items; never rely on colour alone (status text accompanies dots).
## Open questions
- Should "Got it" also allow snooze? (Not in MVP.)
