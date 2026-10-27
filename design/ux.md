# Nudge: UX spec
## Users and primary jobs
One user: a busy person who misses meetings despite Google Calendar banners. Jobs: (1) get a loud early heads-up, (2) get an unmissable final warning, (3) trust the app is running and in sync.
## Information architecture
No windows. Menu bar only: S01 Menu bar menu; alerts S03 Five-minute banner and S02 Full-screen warning.
## Key flows
1. First run: S01 shows no-access state → user allows calendar access / adds Google account → S01 normal.
2. T-5 min: S03 banner + sound.
3. T-1 min: S02 covers all screens → "Got it" dismisses.
4. Sync failure: S01 icon turns red; menu explains and keeps alerting from saved data → Retry.
## Design system
- Colours: alert red #7A0F0A, error red #B3261E, ok green #1E7F3C, amber #A35200, text #1D1D1F, muted #5F6368, menu bg #F6F6F7, accent #0B57D0.
- Type: system font (SF). Menu 13px; banner title 13px semibold; full-screen: 96px title, 200px countdown, 24–28px secondary.
- Spacing: 6/10/14px in menus; 40px padding full-screen.
- Components: menu row, status line, primary button (white on red).
- Tone: short, calm, plain. No exclamation marks.
## Accessibility
Contrast ≥ 4.5:1 (white on #7A0F0A ≈ 11:1). Everything is keyboard operable; Return/Esc dismiss S02; visible focus ring; dismiss button focused on open; VoiceOver labels on all items; never rely on colour alone (status text accompanies dots).
## Open questions
- Should "Got it" also allow snooze? (Not in MVP.)
- Show meeting video link in S02? (Not in MVP.)
