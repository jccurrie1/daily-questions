# Daily Questions: tech stack

Status: initial draft. The MVP is confirmed for Jared's Mac only, with local storage. The framework choices below are proposed.

## Product context

The supplied designs show a macOS app for daily yes/no questions, question management, and personal progress reports. They include a full app window and a menu bar panel for quick answers.

Use the designs as visual context. Their example counts, dates, labels, and controls do not define final product rules.

Streaks are outside the MVP scope.

## Proposed stack

| Area | Technology | Use in this project |
| --- | --- | --- |
| Platform | Native macOS | MVP for Jared's Mac only. |
| Language | Swift | App logic, data models, and calculations. |
| Development and builds | Xcode | Build, run, debug, test, and package one macOS app target. Pin the Xcode version when the app project is created. |
| Main interface | SwiftUI | Today, Questions, Analytics, and Settings views. Use native controls and layout components. |
| Navigation | SwiftUI `NavigationSplitView` | Sidebar navigation and the question list/detail layout. [Apple documentation](https://developer.apple.com/documentation/swiftui/navigationsplitview). |
| Menu bar panel | SwiftUI `MenuBarExtra` with window style | A panel that shows today's questions and answer controls. [Apple documentation](https://developer.apple.com/documentation/swiftui/menubarextra). |
| Persistent data | SwiftData | Store questions and daily answers on the Mac. Share one model container between the main window and menu bar panel. [Apple documentation](https://developer.apple.com/documentation/swiftdata/modelcontainer). |
| UI state | SwiftUI state and bindings; Observation when needed | Keep temporary selection and edit state in the views. Add an observable model only when state must be shared. [Apple documentation](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app). |
| Preferences | `@AppStorage` / `UserDefaults` | Small settings, separate from question and answer history. [Apple documentation](https://developer.apple.com/documentation/swiftui/settings). |
| Charts | Swift Charts | Weekday bars and trend lines. Use SwiftUI shapes for simple progress rings. [Apple documentation](https://developer.apple.com/documentation/charts). |
| Dates and calculations | Foundation and Swift | Calendar dates, date formatting, and progress calculations. Keep metric calculations independent of the views. |
| Interface icons | SF Symbols | Standard navigation and action icons. Create a separate original app icon. [Apple documentation](https://developer.apple.com/sf-symbols/). |
| Logic tests | Swift Testing | Check date handling, metric calculations, and answer updates. [Apple documentation](https://developer.apple.com/xcode/swift-testing/). |
| UI tests | XCTest / XCUITest | Check the main answer and question-editing flows once implemented. [Apple documentation](https://developer.apple.com/documentation/xctest). |
| Version control | Git | Track the app and its documentation in this repository. |

Set the deployment target during setup to support the macOS version installed on Jared's Mac. The proposed SwiftData and Observation stack requires **macOS 14 or later**. Compatibility with other Macs or older systems is outside the MVP scope. [SwiftData availability](https://developer.apple.com/videos/play/wwdc2023/10189/), [Observation availability](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app).

Use APIs available on the selected minimum OS. Choose the exact Swift and Xcode versions when creating the app project; this document does not claim a toolchain is installed or tested.

## App structure and data

Start with one app process. The main window and menu bar panel use the same stored questions and answers. Compute reports from that data on the device.

```text
Main window + menu bar panel
             |
      Shared SwiftData store
             |
     Local metric calculations
             |
       Swift Charts views
```

Keep the initial data model small: questions and answers associated with a question and a calendar day. The only answer choices are **Yes** and **No**, stored as a Boolean. Until the user selects one, no answer is recorded. Updating an answer must not create a second answer for the same question and day.

The app uses a fixed five-day week: Monday through Friday. Users cannot select or change the days. Saturday and Sunday are excluded.

Use calendar operations for day boundaries. Define the time-zone policy before implementing history. Decide how question edits, archiving, and deletion affect past reports before finalizing the schema.

Handle save failures visibly and preserve the user's input. Verify that saved answers survive an app restart and that changes appear in both app surfaces.

## Initial dependency and service choices

The MVP runs on Jared's Mac with local storage and offline use. Cloud sync, a hosted backend, accounts, and a network API are outside the MVP scope. Calculate personal progress reports locally.

Build and run the app locally with Xcode. Public distribution, App Store submission, and an automatic update service are outside the MVP scope.

Start with Apple's frameworks and no third-party packages. Add AppKit only if a specific window or menu bar behavior cannot be implemented with SwiftUI. Use native controls, system colors, and materials; verify keyboard access, VoiceOver labels, and appearance on the supported macOS versions.

## Open decisions

| Decision | Starting proposal or question |
| --- | --- |
| Deployment target | Check the macOS version on Jared's Mac during setup. |
| History changes | Define the effects of editing, archiving, and deleting questions, and whether past answers can be changed. |
| Day boundaries | Define which time zone determines a day and what happens when the user travels. |

## Verification status

Framework capabilities were checked against the linked Apple documentation. No app code, dependencies, build configuration, or runtime behavior has been implemented or tested.
