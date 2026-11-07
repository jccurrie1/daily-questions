import AppKit
import SwiftUI

@main
struct DailyQuestionsApp: App {
    @State private var store: DailyStore?
    @State private var sync: SyncCoordinator?
    @State private var startupError: String?

    init() {
        do {
            let store = try Self.openStore()
            _store = State(initialValue: store)
            _sync = State(initialValue: SyncCoordinator(store: store))
        } catch { _startupError = State(initialValue: error.localizedDescription) }
    }

    var body: some Scene {
        Window("Daily Questions", id: "main") {
            Group {
                if let store, let sync { DesktopView(store: store, sync: sync) }
                else {
                    ContentUnavailableView {
                        Label("Cannot open local data", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(startupError ?? "The local store could not be opened.")
                    } actions: {
                        Button("Retry") {
                            do {
                                let store = try Self.openStore()
                                self.store = store
                                sync = SyncCoordinator(store: store)
                                startupError = nil
                            } catch { startupError = error.localizedDescription }
                        }
                    }
                    .foregroundStyle(.red)
                    .frame(minWidth: 600, minHeight: 400)
                }
            }
            .tint(Palette.ink)
            .onAppear { DockIcon.show() }
            .onDisappear { DockIcon.hide() }
        }
        .defaultSize(width: 1120, height: 740)
        .defaultPosition(.center)
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            if let store, let sync {
                MenuPanel(store: store, sync: sync)
                    .tint(Palette.ink)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Text("Cannot open local data. Open Daily Questions to retry.")
                        .foregroundStyle(.red)
                    Spacer()
                    OpenWindowButton()
                }
                .padding(20)
                .frame(width: 340)
                .tint(Palette.ink)
            }
        } label: {
            Image(nsImage: Self.statusIcon)
                .accessibilityLabel("Daily Questions")
        }
        .menuBarExtraStyle(.window)

        #if VERIFICATION
        // The same panel can be exercised when system menu bar automation is unavailable.
        Window("Menu Panel Verification", id: "verification-panel") {
            if let store, let sync {
                MenuPanel(store: store, sync: sync)
                    .tint(Palette.ink)
            }
        }
        .windowResizability(.contentSize)
        #endif
    }

    private static var statusIcon: NSImage {
        let logo = NSImage(named: "AppLogo") ?? NSImage()
        return NSImage(size: NSSize(width: 20, height: 20), flipped: false) { bounds in
            NSBezierPath(ovalIn: bounds).addClip()
            logo.draw(in: bounds)
            return true
        }
    }

    private static func openStore() throws -> DailyStore {
        #if DEBUG
        #if VERIFICATION
        let verification = true
        #else
        let verification = ProcessInfo.processInfo.arguments.contains("--verification")
        #endif
        // UI verification uses its own store and cannot alter the user's records.
        if verification {
            let directory = URL.applicationSupportDirectory.appending(path: "DailyQuestionsVerification")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return try DailyStore(storageURL: directory.appending(path: "Verification.store"))
        }
        #endif
        return try DailyStore()
    }
}

@MainActor
enum DockIcon {
    static func show() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }

    static func hide() {
        NSApp.setActivationPolicy(.accessory)
    }
}
