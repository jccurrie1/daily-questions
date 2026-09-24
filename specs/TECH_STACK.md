# Daily Questions: tech stack

Status: implemented MVP. Native macOS, Swift, SwiftUI, and local SQLite storage are confirmed for an MVP on Jared's Mac only. SwiftData is confirmed for local SQLite persistence. Supporting UI frameworks use native Apple APIs.

## Product context

The [project transcript](../transcript.md) defines three features:

- A menu bar panel opened from the app logo, limited to viewing today's questions and answering Yes or No.
- A desktop window opened from the Dock for creating, viewing, editing, and archiving questions.
- A desktop performance view where selecting a question shows one Monday–Friday week of recorded answers at a time.

Use the latest [design references](../designs/README.md): a Liquid Glass sidebar and opaque neutral main content. There is no desktop Today screen. Questions are never deleted, and saved answers cannot be updated.

Use the current gallery for implementation. Earlier designs are superseded; sample dates and values are illustrative. The feature specs define behavior.

Streaks are outside the MVP scope.

Reserve red for app error states. Archive controls, No answers, and unanswered states use neutral styling. Pair error color with explanatory text. Native macOS window controls retain their system colors.

Use the [Mononote-inspired palette](../designs/README.md#palette): off-white surfaces, charcoal text and actions, and gray secondary elements. Apply it to app controls, charts, badges, and the app icon. Blue and green are not app accent colors. Wallpaper colors can show through the Liquid Glass sidebar; the main content remains neutral and opaque.

## Implemented stack

| Area | Technology | Use in this project |
| --- | --- | --- |
| Platform | Native macOS | MVP for Jared's Mac only. |
| Language | Swift | Confirmed for app logic, data models, and calculations. |
| Development and builds | Xcode 26.3 | One macOS app target and shared `DailyQuestions` scheme. Verified with Xcode build 17C529 and Swift 6.2.4, using Swift 6 language mode. |
| Main interface | SwiftUI | Confirmed for the menu bar and desktop interfaces. The desktop contains question management and per-question performance. |
| Navigation | SwiftUI `NavigationSplitView` | Implement the selected sidebar and question list/detail layout; use native Liquid Glass sidebar treatment on macOS 26. [Apple documentation](https://developer.apple.com/documentation/swiftui/navigationsplitview). |
| Menu bar panel | SwiftUI `MenuBarExtra` with window style | A panel that shows today's questions and answer controls. [Apple documentation](https://developer.apple.com/documentation/swiftui/menubarextra). |
| Persistent data | SQLite | Confirmed local database for questions and daily answers. Both app surfaces use the same data. |
| Persistence adapter | SwiftData | Connect Swift models and SwiftUI to local storage using SwiftData's default Core Data-backed SQLite store. Share one model container between the main window and menu bar panel. Confirmed by the user after the transcript. [Apple documentation](https://developer.apple.com/documentation/swiftdata/modelcontainer). |
| UI state | SwiftUI state and bindings; Observation when needed | Keep temporary selection and edit state in the views. Add an observable model only when state must be shared. [Apple documentation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app). |
| Charts | Swift Charts | A read-only graph for one Monday–Friday week of the selected question's answers, using separate Yes/No levels and missing-answer labels. [Apple documentation](https://developer.apple.com/documentation/charts). |
| Dates and calculations | Foundation and Swift | Calendar dates, week navigation, date formatting, and answer-completion counts. |
| Interface icons | SF Symbols | Standard navigation and action icons. Use the approved question-mark character for the app icon. [Apple documentation](https://developer.apple.com/sf-symbols/). |
| Logic checks | Swift executable checks | Run real SwiftData stores and date/report assertions through the scripts in this repository. |
| UI verification | Computer use | Exercise the native app with isolated test data. See the verification record for coverage and limits. |
| Version control | Git | Track the app and its documentation in this repository. |

The project targets **macOS 26.0 or later** and was built on Jared's Mac running macOS 26.6.2. Compatibility with other Macs or older systems is outside the MVP scope.

Use APIs available on the selected minimum OS. The app uses local ad-hoc signing and App Sandbox. No developer team or third-party packages are configured.

## App structure and data

Use one app process. The main window and menu bar panel use the same stored questions and answers. Read the selected question's performance from that data on the device. The storage connection is:

```text
SwiftUI menu bar + desktop views
              |
     SwiftData
              |
           Core Data
              |
      Local SQLite database
```

Keep the initial data model small: questions and answers associated with a question and a calendar day. The only answer choices are **Yes** and **No**, stored as a Boolean. Until the user selects one, no answer is recorded. Save at most one answer per question per day. Once saved, it cannot be replaced, cleared, or deleted, including on the current day. A failed save can be retried.

Reports show one week at a time, defaulting to the current week, with previous/next week navigation up to the current week. Archived questions retain readable history. The menu bar completion footer counts both Yes and No as answered; reports do not show Yes-rate percentages or multiweek summaries.

The app uses a fixed five-day week: Monday through Friday. Users cannot select or change the days. Saturday and Sunday are excluded.

Use calendar operations for day boundaries. Use the Mac's local date with a midnight boundary. Store Gregorian date keys (YYYY-MM-DD), preserving the original keys when the time zone changes. Give questions stable identifiers, creation dates, current wording, and archive state/date. Wording edits update labels in all reports but preserve answer associations. Archiving stops daily prompts and retains the question and all answers. There is no permanent question deletion.

Handle save failures visibly and preserve the user's input. Verify that saved answers survive an app restart and that changes appear in both app surfaces.

## Initial dependency and service choices

The MVP runs on Jared's Mac with local storage and offline use. Cloud sync, a hosted backend, accounts, and a network API are outside the MVP scope. Read weekly answer reports locally.

Build and run the app locally with Xcode. Public distribution, App Store submission, and an automatic update service are outside the MVP scope.

Start with Apple's frameworks and no third-party packages. Add AppKit only if a specific window or menu bar behavior cannot be implemented with SwiftUI. Use native controls with the documented neutral app palette; verify keyboard access, VoiceOver labels, and appearance on the supported macOS versions.

## Confirmed storage and date decisions

Use SwiftData with local SQLite. The Mac's local date starts at midnight; saved answers retain their original date keys across time-zone changes.

## Verification status

The Debug and Release builds pass with Xcode 26.3. SwiftData and date regression checks pass. Computer use verified creation, blank validation, editing/cancel, archive history, weekly reports, answer locking, and restart persistence using separate verification data. The system menu bar control could not be exercised because computer use timed out on that surface; the same menu panel was verified in a dedicated test window. See the [verification record](VERIFICATION.md).
