# Question selection design check

September 26, 2026. Result: passed for the selected question-list design.

- Target: [option 3](designs/question-selection/expand-in-place.png), 1511 × 1041 pixels.
- Runtime: [installed macOS app](designs/question-selection/implemented.png), 2254 × 1552 pixels, a 1127 × 776 point window at 2× density. This native app has no CSS viewport.
- Compared both images together at the same relative window scale, with the first question expanded and the second collapsed.

The main layout, disclosure rows, title hierarchy, indented field, and nearby actions match the selected concept. The sidebar and logo retain the existing implementation. The first pass exposed a filter alignment and row-title size difference; both were corrected before the final build. Native control shapes and inactive-window colors differ from the generated concept. Save Changes and Cancel correctly remain disabled until text changes. The runtime capture includes the system screen-sharing indicator and pointer.

Isolated UI checks passed for opening, switching, and collapsing rows; new-question selection; cancel; blank-text validation; save; archive; archived read-only expansion; and opening the selected performance report. Accessibility inspection confirmed named row buttons with Expanded/Collapsed values. Full VoiceOver operation was not tested.

The final installed build was opened against the existing records and its expanded state was checked without changing stored data. The Debug build, store checks, and whitespace check passed. No remaining actionable difference was found in the requested question-selection scope.
