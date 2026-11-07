import AppKit
import SwiftUI

struct MacSettingsView: View {
    let sync: SyncCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Settings").font(.system(size: 30, weight: .bold))
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sync").font(.title3.weight(.semibold))
                    SyncSettingsCard(sync: sync, onChooseFolder: chooseFolder)
                        .frame(maxWidth: 560, alignment: .leading)
                    Text("Choose a folder in iCloud Drive to share questions and answers with your iPhone. Pick the same folder in the iPhone app.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 560, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(28)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .task { await sync.syncNow() }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Use Folder"
        panel.message = "Choose a folder for Daily Questions sync files."
        if panel.runModal() == .OK, let url = panel.url {
            sync.setFolder(url)
        }
    }
}
