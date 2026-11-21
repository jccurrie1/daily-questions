import SwiftUI

struct SettingsToolbar: ViewModifier {
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
                    SettingsView()
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
    func settingsToolbar() -> some View {
        modifier(SettingsToolbar())
    }
}

struct SettingsView: View {
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinuteOfDay") private var reminderMinuteOfDay = 17 * 60
    @State private var reminderError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
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

                if let message = reminderError {
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
        .onChange(of: reminderEnabled) { updateReminder() }
        .onChange(of: reminderMinuteOfDay) { updateReminder() }
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
