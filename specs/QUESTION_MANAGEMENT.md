# Desktop: question management

Status: MVP requirements updated from the transcript and later decisions.

Sources: [transcript](../transcript.md), [current designs](../designs/README.md#questions).

## Problem Statement

The user needs to create, view, edit, and archive daily questions without losing answer history.

## Solution

Open the desktop window from the Dock to manage questions and view performance. Use the latest Liquid Glass sidebar design. There is no desktop Today screen, and questions are never deleted.

## User Stories

1. As the user, I want to open the app from the Dock, so that I can manage questions in a desktop window.
2. As the user, I want to create a question, so that I can track another activity.
3. As the user, I want to edit question wording, so that I can correct or clarify it.
4. As the user, I want to cancel an edit, so that I can retain the saved wording.
5. As the user, I want to archive a question, so that the app stops asking it and keeps its history.
6. As the user, I want to view archived questions, so that I can inspect their recorded answers.
7. As the user, I want changes to survive a restart and appear in the menu bar, so that both views use the same records.
8. As the user, I want to select a question and open its performance, so that I can inspect weekly answers.

## Implementation Decisions

- Build the desktop UI in SwiftUI with the shared local SQLite-backed store. Use SwiftData with its local SQLite store.
- Use the latest Liquid Glass sidebar with blurred wallpaper visible through it. Main content stays opaque and neutral. Use the approved character logo and Questions/Analytics navigation. No Today navigation.
- Command+B opens or closes the desktop sidebar. Do not add a visible shortcut label, menu command, or toggle control for this shortcut.
- The question list has Active and Archived views. New questions are active. The editor provides Save Changes and Cancel; active questions also have Archive.
- Each question has a stable identifier, current text, creation date, and archive state/date. Answers refer to its stable identifier.
- All questions use Yes/No and the fixed Monday–Friday schedule. Creating a question does not create earlier answers.
- Reject empty or whitespace-only text. On save failure, keep entered text and show a factual error.
- Editing updates the existing question's wording everywhere, including historical reports. Keep its identifier and answers. Do not create wording versions or rewrite answers.
- Archiving removes the question from active lists and daily prompts. Keep the question and all answers in storage. Archived questions remain selectable for performance review.
- Do not provide Delete controls, delete menu items, or permanent question deletion. Archive uses neutral styling.
- View performance opens the selected question's weekly report. Analytics provides access to the same reports.
- Archived questions remain available for viewing text and history. Restoring them is outside this MVP.

## Testing Decisions

- Use the desktop flow and saved results as the main boundary. Create a question, restart, and verify it appears in the active list and weekday menu bar.
- Edit text after an answer exists. Verify the same question and answers remain and historical reports show the new wording.
- Cancel an edit; verify stored text is unchanged. Reject blank text and preserve input after save failure.
- Archive a question with answers. Verify it leaves active lists and prompts but remains in Archived with its history after restart.
- Verify no question deletion or desktop Today screen exists.
- Open performance for an active and an archived question; verify the correct question is selected.
- Check keyboard access, accessible labels, and readable sidebar text over the glass material.
- The feature is implemented. Completed checks and remaining manual checks are listed in the [verification record](VERIFICATION.md).

## Out of Scope

- Permanent deletion, restoring archived questions, and saved-answer updates.
- A desktop Today or daily-answering screen.
- Custom schedules, other answer types, question categories, and settings screens.
- Streaks, accounts, cloud sync, and public distribution.

## Further Notes

These decisions supersede the transcript's use of CRUD where it implies deletion. Archive preserves history. Updating question wording does not permit updating answers.
