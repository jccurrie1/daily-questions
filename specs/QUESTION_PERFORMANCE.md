# Desktop: question performance

Status: MVP requirements updated from the transcript and later decisions.

Sources: [transcript](../transcript.md), [current designs](../designs/README.md#performance).

## Problem Statement

The user needs to see whether they did an activity during a specific working week.

## Solution

Select an active or archived question and view its recorded answers for one Monday–Friday week at a time. The report is read-only.

## User Stories

1. As the user, I want a report for one question, so that I can inspect that activity's answers.
2. As the user, I want the current question wording above the graph, so that I can identify the activity.
3. As the user, I want five dated weekday positions, so that I can read the week in order.
4. As the user, I want Yes, No, and missing answers to look different, so that missing data does not imply No.
5. As the user, I want to move between weeks, so that I can inspect history one week at a time.
6. As the user, I want archived question history, so that stopping a question does not remove its records.
7. As the user, I want labels as well as chart marks, so that I can read results without relying on color.

## Implementation Decisions

- Use the shared local question and answer store. Use Swift Charts.
- Follow the latest Liquid Glass sidebar design, with opaque neutral main content. No desktop Today screen.
- Show exactly one calendar week, Monday through Friday, with its date range and weekday dates. Do not aggregate across weeks.
- Default to the current week. Previous/next controls move one week at a time; disable next at the current week. On weekends, show that week's Monday–Friday records.
- Read only the selected question's answers within that week. Archived questions use the same report.
- Use separate Yes and No levels with discrete marks and weekday labels. Do not connect marks with a trend line.
- Missing answers have no Yes/No mark and a factual label such as Not answered. This is not a third answer option and must not become a stored No.
- Future days, days before creation, and days after archiving have no answer due. Label them as such instead of missed answers. Retain any saved answer on the archive date. Do not invent historical answers.
- Use current question wording for every week, even if it changed after answers were saved.
- Show new saved menu bar answers when the report is open or reopened. Saved values cannot be edited from any app surface.
- Derive the report from saved answers; do not maintain a separate performance database.
- If a week has no saved answers, show a factual empty state and weekday labels, not a failure score.

## Testing Decisions

- Use known saved answers and the desktop report as the main boundary. Show Yes on Monday, No on Tuesday, and no answer on Wednesday; verify three distinct display states.
- Verify five positions in date order and the correct range. Week navigation must exclude adjacent-week records and other questions.
- Check current-week default, next-week limit, and weekend display with controlled dates.
- Save a new menu bar answer and verify it appears in an open report. Verify no controls can change it.
- Change question wording and archive it; verify history remains readable under current wording.
- Verify empty weeks, future days, pre-creation days, and days after archiving do not appear as No or failed activity.
- Check keyboard navigation and accessible date/answer labels.
- The feature is implemented. Completed checks and remaining manual checks are listed in the [verification record](VERIFICATION.md).

## Out of Scope

- Multiweek aggregates, trends, streaks, Yes-rate percentages, scores, and best-day rankings.
- Updating saved answers, past-day entry, custom date ranges, and weekend answers.
- Cross-question dashboards, exports, accounts, cloud sync, and public distribution.

## Further Notes

One-week reporting is confirmed. Current-week default and previous/next navigation are the minimal navigation choices used in the revised design. Question management defines archiving and wording changes. Use the confirmed local-date policy in the tech stack document.
