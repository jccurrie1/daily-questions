# Analytics: 30-day overview

Status: implemented.

## Problem Statement

Choosing **Analytics** in the sidebar shows nothing useful unless a question is already selected on the Questions screen. There is no Analytics home screen, so the user cannot compare recent activity across questions.

## Solution

Make Analytics open a read-only overview of the last 30 days with one activity card for each active question. Each card shows a Monday–Friday grid where a saved Yes is filled and every other weekday uses the No style. Clicking a card opens the existing per-question Analytics page.

## User Stories

1. As the user, I want Analytics in the sidebar to always open an overview, so that I don't need to select a question first.
2. As the user, I want one card for each active question, so that I can compare recent activity across questions.
3. As the user, I want the last 30 days with the date range in the header, so that I know which period I'm looking at.
4. As the user, I want only Monday through Friday columns, so that the grid matches the days when questions can be answered.
5. As the user, I want a filled box for each saved Yes, so that I can scan the days when I answered Yes.
6. As the user, I want today marked, so that I can find the current date in each grid.
7. As the user, I want every card to be the same size, so that the grid stays tidy when question lengths differ.
8. As the user, I want to open a question's full Analytics page from its card and return to the overview, so that I can inspect one question in detail.
9. As the user, I want the "View analytics" button on the Questions screen to keep opening a question directly and return to Questions, so that the existing flow does not change.
10. As the user, I want the overview to update when a new answer is saved, so that it matches the menu bar panel.
11. As the user, I want dates and answers available to VoiceOver and keyboard users, so that I can read the grid without sight or a pointer.
12. As the user, I want the overview to work in light and dark appearance.

## Implementation Decisions

- The window is today plus the 29 days before it, in the Mac's local date (`LocalDay`). The header reads "Last 30 days · Sep 8 – Oct 7, 2026" (`MMM d – MMM d, yyyy`) next to a Yes/No legend; the row wraps on narrow widths.
- One row per Monday–Friday week that touches the window, oldest at the top, labeled with that week's Monday. Days in the first week before the window are left out with no box drawn. A week whose weekdays all fall before the window (when the window starts on a Saturday or Sunday) is not shown. Future weekdays in the current week are drawn.
- Cards use an adaptive grid (minimum 236pt wide, 16pt gap). The question title is always exactly two lines tall with a trailing ellipsis; the full text is available as pointer help.
- **Two visual states only.** A saved `true` is Yes. Every other weekday — saved No, not answered, future, before creation — uses the No style. Each cell's accessibility value and pointer help also say only Yes or No. This intentionally differs from the [four-week activity](FOUR_WEEK_ACTIVITY.md) grid, which keeps exact statuses; that grid on the per-question page is unchanged. The overview never writes No to the store.
- Only active questions appear, in the store's order (`createdDay`, then `text`). There is no count, percentage, streak, or footer.
- Clicking a card opens `QuestionPerformanceView`; its back button reads "Analytics" and returns to the overview. "View analytics" on the Questions screen opens `QuestionPerformanceView` with a "Questions" back button, as before. Choosing a sidebar item clears any open question.
- Read-only. The existing `TimelineView` and `@Observable` store keep the overview current. No schema change, service, or dependency.

## Testing Decisions

- `scripts/check-analytics.sh` checks the observable week rows from `AnalyticsOverview.activityWeeks`: a partial first week, a window starting on a weekend, Saturday and Sunday, a local Monday midnight rollover, a year boundary, a DST change, and five time zones.
- Rendered offscreen in dark appearance with sample answers to check layout against the design reference, including equal card heights with one- and two-line titles.

## Out of Scope

- Archived questions in the overview.
- Distinguishing No, not answered, and no answer due on the overview.
- Counts, rates, streaks, custom date ranges, or paging to older periods.
- Changing or entering answers from Analytics.

## Further Notes

The design reference is the "Analytics overview" handoff (`Analytics.dc.html`). Its sample answers are illustrative.
