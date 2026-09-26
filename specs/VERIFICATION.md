# MVP verification

## Expandable question list — September 26, 2026

- Normal macOS Debug build passed after implementing option 3. `scripts/check-store.sh` passed, including failed-save rollback and retry.
- A separate verification build and store passed row expansion, switching, collapse, automatic selection after creation, cancel, blank-text validation, save, archive, archived read-only viewing, and navigation to the selected question's performance report.
- Accessibility inspection confirmed named row buttons with Expanded/Collapsed values and hints.
- Updated and opened `/Applications/Daily Questions.app`. Checked the final expanded layout against the selected concept without changing production records. See [design check](../design-qa.md) and its runtime screenshot.
- `git diff --check` passed. Full VoiceOver operation was not tested.

## Original MVP checks

Date: September 24, 2026. Xcode 26.3, Swift 6.2.4, macOS 26.6.2, Apple Silicon.

## Build and automated checks

- Normal Debug and Release builds passed. No third-party packages.
- `scripts/check-store.sh` passed with real SwiftData in-memory and temporary on-disk stores: trimmed/blank text, question identity through edits, Yes/No answers, repeated-write rejection, archive preservation, restart persistence, weekend/pre-creation rejection, and local calendar boundaries.
- Read-only SwiftData storage produced real save failures. Checks confirmed rollback of edited text/archive state, no ghost records or false saved answers, and retry after reopening writable storage. Expected read-only errors appear in the test log.
- `scripts/check-report.sh` passed: historical Monday–Friday keys across five time zones, current-week change at local Monday midnight, and Gregorian formatting under a non-Gregorian locale.
- `git diff --check` passed.

## Computer-use checks

Used a verification app with a separate bundle identifier and local store. Production records were not changed by these tests.

- Blank question creation displays an error. Valid questions appear in the active list and survive restart.
- Cancel restores stored wording. Save Changes updates wording in the list and report without losing the answer.
- Yes and No both save and lock both controls. Completion counts both values. Saved and unanswered rows remain distinct after restart.
- Archive removes a question from the active list and answer panel. The archived question remains selectable and its answer remains in the weekly report.
- Current report has five weekday positions, dated range, and distinct Yes/No/missing/not-due states. Previous week excludes current answers. Next is disabled at the current week.
- Creating from the Archived list switches to Active and keeps the new question selected.
- Visually inspected the neutral palette, native sidebar, logo, question editor, answer bubbles, and chart. Corrected chart-label alignment and saved-answer contrast during the checks.
- Accessibility inspection found explicit answer values, saved/disabled states, week navigation labels, and a date/answer summary for the chart. Keyboard text entry and editing were exercised.

Sidebar shortcut follow-up: the normal Debug app rebuilt and relaunched successfully. Computer use verified that Command+B hides and restores the sidebar, including with the question text field focused, without changing its text or selection. After restoring the original sidebar design and native toggle button, computer use verified that both the button and Command+B hide and restore the sidebar. No Command+B shortcut label is displayed. No stored records were changed.

## Limits

Computer use timed out when targeting the system menu bar. The answer checks used the exact `MenuPanel` view in a verification-only window, so they verify the panel and shared persistence but do not prove clicking the actual menu bar icon opens it. Closing the main window and reopening from the Dock was not conclusively verified through the computer-use tool. Full VoiceOver operation and changed Reduce Transparency settings were not tested. Weekend, midnight, time-zone, and storage-failure rules were checked with controlled automated tests, not by changing this Mac's settings.

## Reproduce isolated UI checks

The `DailyQuestions-Verification` Xcode scheme uses a separate database via its `--verification` launch argument. To also expose the menu panel as an ordinary test window:

```sh
xcodebuild -project DailyQuestions.xcodeproj -scheme DailyQuestions \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/daily-questions-verification \
  PRODUCT_BUNDLE_IDENTIFIER=com.jaredcurrie.DailyQuestions.Verification \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=DEBUG VERIFICATION' build
```

Open the resulting app. Its Window menu contains Menu Panel Verification. The test window and compile-time verification mode are absent from the normal app. The app does not seed example questions into the real store.
