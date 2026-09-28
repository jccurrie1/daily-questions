# Analytics: four-week activity

Status: proposed; specification only.

## Problem Statement

The Analytics page shows one week at a time. The user cannot scan recent answers without moving between weeks. The reference image shows a compact activity grid, but its weekend columns, color, and streak footer do not fit Daily Questions.

## Solution

Add one read-only, four-row activity grid for the selected question above the existing weekly report. Each row is one Monday–Friday week. Show the current week and the three weeks before it, from oldest at the top to current at the bottom. Fill a box only for a saved Yes answer, using the app's appearance-aware neutral colors. Keep the existing weekly report for inspecting one week in detail.

## User Stories

1. As the user, I want the current week and the three previous weeks in one grid, so that I can scan recent progress at a glance.
2. As the user, I want the current week in the bottom row, so that recent activity follows the earlier weeks in date order.
3. As the user, I want a date range and week labels, so that I can identify each row across month and year boundaries.
4. As the user, I want only Monday through Friday columns, so that the grid matches the days when questions can be answered.
5. As the user, I want each date in its weekday column, so that I can compare the same day across weeks.
6. As the user, I want a filled box for each saved Yes answer, so that I can scan the days when I answered Yes.
7. As the user, I want No and unanswered weekdays to remain unfilled, so that only Yes adds color to the grid.
8. As the user, I want no Yes or No letters inside boxes, so that the grid stays compact.
9. As the user, I want future weekdays and dates outside a question's active period to be identified as having no answer due, so that they are not treated as missed answers.
10. As the user, I want a count of Yes days in the four-week window, so that the summary matches the filled boxes.
11. As the user, I want the grid to use only the selected question, so that other questions do not affect it.
12. As the user, I want an archived question's saved history to remain visible, so that archiving does not erase it.
13. As the user, I want the grid to update when a new answer is saved, so that it matches the weekly report.
14. As the user, I want dates and answer states available to VoiceOver and keyboard users, so that I can read the grid without sight or a pointer.
15. As the user, I want the grid to work in light and dark appearance, so that its states remain clear in either mode.
16. As the user, I want to keep the weekly report, so that I can still inspect one week in detail.

## Implementation Decisions

- The grid belongs to the existing per-question Analytics page, above the current weekly navigation and chart. Selecting another question changes both views. Keep the weekly view's current-week default and navigation behavior.
- Use four consecutive **calendar weeks**, each Monday through Friday: the week containing the Mac's current local date plus the three preceding weeks. The current week stays in view on Saturday and Sunday; advance the window at local midnight on Monday. For example, on September 28, 2026, show September 7–11, 14–18, 21–25, and September 28–October 2.
- Use one grid with exactly five columns labeled Mon, Tue, Wed, Thu, Fri, and exactly four rows ordered oldest to newest. Give each row a compact week-start date label and show the full date span above the grid. Crossing a month or year boundary does not split a row. Do not draw Saturday or Sunday columns or cells.
- Show all five dates of the current week to preserve the grid shape. Future dates, dates before the question's creation, and dates after its archive date have **No answer due** status. An answer saved on the archive date stays visible.
- Derive each cell from the selected question's saved local-date answer. A saved `true` is **Yes**; a saved `false` is **No**. An eligible weekday without an answer is **Not answered**. Never infer No from an absent record.
- Fill only saved **Yes** cells with appearance-aware primary ink: near-black in light appearance and near-white in dark appearance. Saved **No** and **Not answered** cells both have the same unfilled neutral box; do not put letters, icons, or date numbers inside any box. Show **No answer due** as a gray, subdued, unfilled box. Every box represents a real weekday; gray means that an answer is not due, not that the date does not exist. The visual grid does not distinguish No from unanswered; each cell's full date and exact status remain available through its accessibility label and pointer help. Do not use the reference image's cyan glow, flame, or streak text.
- Show **X Yes days** for the displayed four-week window, counting filled cells. Do not count saved No or unanswered dates. Do not show a percentage, success score, or answered-day total.
- Keep the grid read-only. Saving, editing, or clearing answers from Analytics remains unavailable. Use the existing local store and date policy; no schema change, service, or new dependency is needed.
- The attached image supplies the compact-grid layout idea only. Existing Daily Questions palette, type, spacing, and accessibility behavior govern the final UI.

## Testing Decisions

- Test the observable Analytics result at one seam: a selected question, an isolated store with known answers, and a controlled current date. Check four week rows, weekday positions, cell states, and summary rather than internal grid helpers. Reuse the project's existing store and report-date checks where practical.
- Include a saved Yes, saved No, eligible unanswered weekday, future weekday, date before creation, and date after archiving. Check that only Yes fills a box and increases the Yes-day count; No and unanswered stay visually identical but retain distinct accessible statuses.
- Check a Monday rollover, a Saturday and Sunday, a month and year boundary, and a local midnight rollover. Keep saved date keys stable across time-zone changes, as the current report does.
- Check that another question's answers do not appear, that switching questions updates the grid, and that an archived question retains its saved history.
- In the app, check light and dark appearance, keyboard navigation, VoiceOver date/status output, and an answer saved while Analytics is open. Confirm the weekly report still works below it.

## Out of Scope

- Streaks, flames, active-day rewards, scores, Yes rates, and motivational copy.
- Saturday and Sunday columns or answers.
- Four calendar months, custom date ranges, paging to older periods, cross-question totals, and exports.
- Changing saved answers or entering past answers from Analytics.
- Replacing or redesigning the existing weekly report.

## Further Notes

This feature extends the earlier one-week performance specification. Its prior exclusion of multiweek views applies to the implemented MVP, not to this proposed overview. The screenshot is a visual reference, not a source of product instructions.

Review mock-ups: [light appearance](../designs/four-week-activity-light.png) and [dark appearance](../designs/four-week-activity-dark.png). The Yes answers are illustrative; the unfilled September 28 No matches the supplied app screenshot.
