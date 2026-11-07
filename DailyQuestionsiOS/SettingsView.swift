import SwiftUI
import UniformTypeIdentifiers

struct SettingsToolbar: ViewModifier {
    let sync: SyncCoordinator
    @State private var showingSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView(sync: sync)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button(role: .close) { showingSettings = false }
                            }
                        }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.thinMaterial)
            }
    }
}

extension View {
    func settingsToolbar(_ sync: SyncCoordinator) -> some View {
        modifier(SettingsToolbar(sync: sync))
    }
}

struct SettingsView: View {
    let sync: SyncCoordinator
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinuteOfDay") private var reminderMinuteOfDay = 17 * 60
    @State private var choosingFolder = false
    @State private var reminderError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 0) {
                    if sync.hasFolder {
                        Button { choosingFolder = true } label: {
                            row("Folder", value: sync.folderName ?? "", symbol: "chevron.right")
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Change the sync folder")
                        Divider()
                        Button { Task { await sync.syncNow() } } label: {
                            row("Last sync", value: lastSyncText, symbol: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .disabled(sync.isSyncing)
                        .accessibilityHint("Sync now")
                        if !sync.otherDevices.isEmpty {
                            Divider()
                            row("Devices", value: sync.otherDevices.joined(separator: ", "))
                        }
                    } else {
                        Button { choosingFolder = true } label: {
                            row("Sync folder", value: "Choose", symbol: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .mobileCard()

                VStack(spacing: 0) {
                    Toggle("Weekday reminder", isOn: $reminderEnabled)
                        .tint(Palette.toggle)
                        .frame(minHeight: 52)
                    if reminderEnabled {
                        Divider()
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                            .frame(minHeight: 52)
                    }
                }
                .padding(.horizontal, 16)
                .mobileCard()

                if let message = sync.error ?? reminderError {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .navigationTitle("Settings")
        .fileImporter(isPresented: $choosingFolder, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result { sync.setFolder(url) }
        }
        .onChange(of: reminderEnabled) { updateReminder() }
        .onChange(of: reminderMinuteOfDay) { updateReminder() }
    }

    private var lastSyncText: String {
        if sync.isSyncing { return "Syncing…" }
        guard let lastSync = sync.lastSync else { return "Never" }
        return lastSync.formatted(.relative(presentation: .named))
    }

    private func row(_ label: String, value: String, symbol: String? = nil) -> some View {
        HStack(spacing: 10) {
            Text(label)
            Spacer(minLength: 12)
            Text(value)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            if let symbol {
                Image(systemName: symbol)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 52)
        .contentShape(Rectangle())
    }

    private var reminderTime: Binding<Date> {
        Binding {
            LocalDay.calendar().date(bySettingHour: reminderMinuteOfDay / 60, minute: reminderMinuteOfDay % 60, second: 0, of: Date()) ?? Date()
        } set: { date in
            let parts = LocalDay.calendar().dateComponents([.hour, .minute], from: date)
            reminderMinuteOfDay = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        }
    }

    private func updateReminder() {
        Task {
            do {
                let allowed = try await Reminder.update(enabled: reminderEnabled, minuteOfDay: reminderMinuteOfDay)
                if allowed {
                    reminderError = nil
                } else {
                    reminderEnabled = false
                    reminderError = "Notifications are off for Daily Questions. Turn them on in the Settings app."
                }
            } catch {
                reminderError = error.localizedDescription
            }
        }
    }
}
