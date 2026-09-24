# Design edit prompts

Historical source only. Superseded by the [current MVP designs](README.md). Any Today screen, Delete control, editable saved answer, or multiweek summary shown here is outside the current MVP.

Tool: built-in imagegen, one edit per original design.

## Menu bar: compact header and answer buttons

Input: `menu-bar-monochrome.png`

Output: `menu-bar-bubbles.png` (current menu bar reference)

Use case: precise-object-edit. This image is the EDIT TARGET, a Daily Questions macOS menu bar popover. Make exactly these two edits. (1) Remove the complete top branding/settings section inside the popover: large sunrise logo, "Daily Questions" title, settings gear, and divider below this section. Remove the section itself, not just its text. Move the Today heading, date, all five question rows and footer upward to close the space. Keep the popover anchored at the same top point below its existing macOS menu bar icon and reduce its height by the removed header height; its bottom edge moves upward. The first content in the panel should now be Today, followed by Mon, Apr 28, 2025. (2) In EVERY question row replace the wide Yes/No segmented control with two separate small circular bubble buttons, approximately 30 pixels in diameter, labeled lowercase "y" and lowercase "n". Put the pair at the right edge of each row with a small gap. A selected y uses a charcoal circle with a white y, the n uses a pale gray circle with dark n. Preserve the current selected states. Buttons must be true circles, not pill-shaped joined segments, speech balloons, or rectangles. Keep all five question texts unchanged, preserve the factual footer "3 of 5 answered", progress bar, "60%", and the neutral Mononote-inspired palette. Preserve the full-screen composition, entire colorful mountain/lake wallpaper, all operating-system menu bar content and small menu bar app icon, popover width and horizontal location, crisp typography, card styling, and rounded panel corners. No new header, no substitute branding, no settings icon elsewhere, no slogans, no streaks, no red or colored application accents. Only remove the header and compact the answer buttons as described.

## Questions: neutral Delete revision

Input: `questions-minimal.png`

Output: `questions-minimal-v2.png` (current reference)

Use case: precise-object-edit. The attached image is the edit target. Make exactly one visual change to this Daily Questions macOS design: restyle the bottom-right "Delete" button to match the neutral secondary "Archive" button beside it, with dark gray text, a pale neutral background, and a subtle gray border. Remove all red and pink from the Delete button. Keep its label, size, location, and rounded shape. Red is reserved for app error states, and this screen shows no error. Preserve the entire rest of the image: exact text, layout, app logo, blue accents, green Active badge, window, desktop wallpaper, menu bar, Dock, and native macOS traffic-light window controls. The operating system window controls retain their native colors. Preserve full-screen framing and aspect ratio. Do not add content, motivational copy, warnings, icons, or a new error state.

## menu-bar

Output: `menu-bar-minimal.png`

Use case: precise-object-edit. Asset type: native macOS UI design reference. The attached image is the EDIT TARGET, not just inspiration. Produce one edited image of this same screen, same full-screen framing and aspect ratio. Preserve the mountain lake desktop wallpaper, menu bar, Dock if present, window position, app logo, typography, blue accent, translucency, functional labels, question text, controls, charts, and example data unless explicitly changed below. Make the UI feel quiet and minimal by removing motivational copy without replacing it with new copy. Repair the background cleanly where text is removed and adjust only nearby spacing when necessary. No new features, decorative elements, slogans, captions, watermarks, or explanatory annotations. Maintain crisp legible interface text. Remove the complete two-line tagline under "Daily Questions": "Work focus. Small questions." and "A more productive you." Keep the title, logo, settings icon, Today heading/date, five question rows, Yes/No controls, and bottom progress summary. Close the excess header gap tastefully. No other edits.

## performance

Output: `performance-minimal.png`

Use case: precise-object-edit. Asset type: native macOS UI design reference. The attached image is the EDIT TARGET, not just inspiration. Produce one edited image of this same screen, same full-screen framing and aspect ratio. Preserve the mountain lake desktop wallpaper, menu bar, Dock if present, window position, app logo, typography, blue accent, translucency, functional labels, question text, controls, charts, and example data unless explicitly changed below. Make the UI feel quiet and minimal by removing motivational copy without replacing it with new copy. Repair the background cleanly where text is removed and adjust only nearby spacing when necessary. No new features, decorative elements, slogans, captions, watermarks, or explanatory annotations. Maintain crisp legible interface text. Remove the complete subtitle "Did you make progress on your app today? Even a small step counts." Remove the entire orange flame / "3 Current Streak days in a row" card, because streaks are excluded. Lay out the remaining three summary cards evenly in the existing row: "80% Completion Rate 16 of 20 days", "42 Total Yes Answers out of 52 days", and "Mon Best Day 100% completion". Preserve all remaining charts, their titles/labels, Recent Weeks table, sidebar, controls, and data. No other edits.

## today

Output: `today-minimal.png`

Use case: precise-object-edit. Asset type: native macOS UI design reference. The attached image is the EDIT TARGET, not just inspiration. Produce one edited image of this same screen, same full-screen framing and aspect ratio. Preserve the mountain lake desktop wallpaper, menu bar, Dock if present, window position, app logo, typography, blue accent, translucency, functional labels, question text, controls, charts, and example data unless explicitly changed below. Make the UI feel quiet and minimal by removing motivational copy without replacing it with new copy. Repair the background cleanly where text is removed and adjust only nearby spacing when necessary. No new features, decorative elements, slogans, captions, watermarks, or explanatory annotations. Maintain crisp legible interface text. Remove the sidebar tagline "Build momentum at work." Remove the complete subtitle under Today: "Answer today’s questions and keep your work momentum going." In the Today’s Progress card remove "Keep going!" and replace the verbose factual sentence "You’ve completed 3 of 5 work questions so far." with the short neutral label "3 of 5 answered". Remove the entire orange flame card including "4-day streak" and "Great consistency!" because streaks are excluded. Rebalance the remaining Today’s Progress card and This week card into the available row, preserving their data, ring, headings, and the factual "18 of 25 completed". Keep all five question rows and Yes/No controls unchanged.

## questions

Output: `questions-minimal.png`

Use case: precise-object-edit. Asset type: native macOS UI design reference. The attached image is the EDIT TARGET, not just inspiration. Produce one edited image of this same screen, same full-screen framing and aspect ratio. Preserve the mountain lake desktop wallpaper, menu bar, Dock if present, window position, app logo, typography, blue accent, translucency, functional labels, question text, controls, charts, and example data unless explicitly changed below. Make the UI feel quiet and minimal by removing motivational copy without replacing it with new copy. Repair the background cleanly where text is removed and adjust only nearby spacing when necessary. No new features, decorative elements, slogans, captions, watermarks, or explanatory annotations. Maintain crisp legible interface text. Remove the sidebar tagline "Work smarter, one day at a time." Remove the full subtitle beneath Questions: "Manage your daily questions. Keep it simple, stay consistent." Keep the Questions heading, New Question button, search field, question list, Edit Question pane, Active control, field labels and contents, Save Changes, Archive, Delete, sidebar navigation, and Settings unchanged. No other edits.
