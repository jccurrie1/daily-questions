import SwiftUI

struct SyncSettingsCard: View {
    let sync: SyncCoordinator
    let onChooseFolder: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Palette.onInk)
                    .frame(width: 40, height: 40)
                    .background(Palette.ink, in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync folder").font(.headline)
                    Text(sync.folderName ?? "Not chosen")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Text("Each device writes its own file in this folder and reads the others. Answers never conflict. The newer wording wins for an edited question.")
                .font(.callout)
                .foregroundStyle(.secondary)
            if sync.hasFolder {
                VStack(spacing: 8) {
                    row("Last sync", value: sync.lastSync.map { $0.formatted(date: .abbreviated, time: .shortened) } ?? "Not yet")
                    row("Other devices", value: sync.otherDevices.isEmpty ? "None found yet" : sync.otherDevices.joined(separator: ", "))
                }
            }
            if let error = sync.error {
                Text(error).font(.callout).foregroundStyle(.red)
            }
            HStack(spacing: 8) {
                if sync.hasFolder {
                    Button(sync.isSyncing ? "Syncing…" : "Sync now") {
                        Task { await sync.syncNow() }
                    }
                    .inkGlassButton()
                    .disabled(sync.isSyncing)
                    Button("Change folder", action: onChooseFolder)
                        .buttonStyle(.glass)
                } else {
                    Button("Choose folder", action: onChooseFolder)
                        .inkGlassButton()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.border, lineWidth: 1))
    }

    private func row(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}
