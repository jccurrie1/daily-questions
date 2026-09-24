# Menu bar: daily answers

Status: MVP requirements updated from the transcript and later decisions. SwiftData and the local calendar-day policy are confirmed.

Sources: [transcript](../transcript.md), [current designs](../designs/README.md#menu-bar).

## Problem Statement

The user needs to answer daily questions without opening the desktop window.

## Solution

Click the app logo in the macOS menu bar to open today's active questions. Record Yes or No once for each question. Saved answers are read-only, including answers saved today.

## User Stories

1. As the user, I want to open my questions from the menu bar, so that I can answer without opening the desktop window.
2. As the user, I want Yes and No choices, so that I can record whether I did an activity today.
3. As the user, I want saved and unanswered questions to look different, so that I know what remains to answer.
4. As the user, I want saved answers to remain after restarting the app, so that I keep my records.
5. As the user, I want archived questions excluded, so that the app stops asking them.
6. As the user, I want a visible save error, so that I do not mistake an unsaved selection for a saved answer.

## Implementation Decisions

- Use one Swift/SwiftUI app with shared local SQLite-backed storage. Use SwiftData with its local SQLite store.
- Use the existing approved character logo in a circular menu bar status icon. Use a compact panel that starts with Today and the date; there is no branding or settings header.
- Use small circular lowercase `y` and `n` controls with accessible names Yes and No. Either selected value uses charcoal.
- Ask active questions Monday through Friday only. There is no day selector, schedule setting, or weekend answering.
- No stored answer means unanswered. Never convert it to No.
- Save at most one answer per question per calendar day. After a successful save, disable both controls for that row and show the saved value with a lock indicator. Expose the saved state in its accessible label.
- Do not replace, clear, or delete saved answers. Reopening the panel or restarting the app does not unlock them. Reject repeat writes for the same question/day without replacing the first value.
- Prevent duplicate submissions while saving. On failure, show a factual error and allow a retry; do not show the selection as saved.
- The footer counts answered active questions, whether Yes or No. Two Yes answers and one No among five questions means 3 of 5 answered, or 60%. This is answer completion, not Yes rate.
- Show current question wording. Archiving removes a question from the panel and preserves its saved answers.
- UI API: SwiftUI `MenuBarExtra` with window style.
- Empty text: "No active questions" on weekdays with none; "No questions on weekends" on Saturday or Sunday. Do not show previous-day answer controls.
- Use the Mac's local date, with each day starting at midnight. Save Gregorian date keys (YYYY-MM-DD); changing time zone must not move existing answers to another date. Refresh the panel at day boundaries.
- App behavior: closing the desktop window leaves the menu bar available; quitting ends both.

## Testing Decisions

- Use the running app and saved data as the main boundary. Save Yes and No on different questions, reopen the panel, and restart the app. Verify both remain and cannot be changed.
- Attempt a repeat save for the same question/day; verify the original record remains unchanged.
- Verify unanswered questions have neither choice selected and are not stored as No. Both Yes and No count toward completion.
- Edit and archive questions in the desktop window; verify current wording appears and archived questions disappear without losing history.
- Check weekday rollover, weekends, no active questions, and retry after save failure with controlled dates and failures.
- Check keyboard operation and accessible labels, including saved state.
- The feature is implemented. Completed checks and remaining manual checks are listed in the [verification record](VERIFICATION.md).

## Out of Scope

- Updating saved answers, past-day entry, and date selection.
- Question management, charts, or settings inside the panel.
- Streaks, configurable schedules, reminders, accounts, cloud sync, and public distribution.

## Further Notes

There is no desktop Today screen. Answering takes place only in this panel. Red is reserved for errors; No, unanswered, and saved states use neutral styling.
