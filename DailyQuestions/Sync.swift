import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

struct SyncReadResult: Sendable {
    var snapshots: [SyncSnapshot] = []
    var unreadable: [String] = []
}

enum SyncFiles {
    static func fileName(deviceID: String) -> String {
        "\(deviceID).json"
    }

    static func write(_ snapshot: SyncSnapshot, to folder: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        let url = folder.appending(path: fileName(deviceID: snapshot.deviceID))
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { url in
            do { try data.write(to: url, options: .atomic) } catch { writeError = error }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }
    }

    static func readOthers(in folder: URL, excluding deviceID: String, downloadTimeout: TimeInterval = 15) throws -> SyncReadResult {
        let own = fileName(deviceID: deviceID)
        var candidates: [String: URL] = [:]
        var coordinationError: NSError?
        var listError: Error?
        NSFileCoordinator().coordinate(readingItemAt: folder, options: [], error: &coordinationError) { folder in
            do {
                for item in try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil) {
                    let name = item.lastPathComponent
                    if name.hasPrefix("."), name.hasSuffix(".json.icloud") {
                        let realName = String(name.dropFirst().dropLast(".icloud".count))
                        let real = folder.appending(path: realName)
                        try? FileManager.default.startDownloadingUbiquitousItem(at: real)
                        candidates[realName] = real
                    } else if name.hasSuffix(".json") {
                        candidates[name] = item
                    }
                }
            } catch { listError = error }
        }
        if let coordinationError { throw coordinationError }
        if let listError { throw listError }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        var result = SyncReadResult()
        for (name, url) in candidates.sorted(by: { $0.key < $1.key }) where name != own {
            waitForDownload(url, timeout: downloadTimeout)
            guard FileManager.default.fileExists(atPath: url.path) else {
                result.unreadable.append(name)
                continue
            }
            var data: Data?
            var readError: NSError?
            NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &readError) { url in
                data = try? Data(contentsOf: url)
            }
            if let data, let snapshot = try? decoder.decode(SyncSnapshot.self, from: data) {
                result.snapshots.append(snapshot)
            } else {
                result.unreadable.append(name)
            }
        }
        return result
    }

    private static func waitForDownload(_ url: URL, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let values = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .ubiquitousItemDownloadingStatusKey])
            guard values?.isUbiquitousItem == true else { return }
            if let status = values?.ubiquitousItemDownloadingStatus, status == .current || status == .downloaded { return }
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
}

@MainActor
@Observable
final class SyncCoordinator {
    private(set) var hasFolder: Bool
    private(set) var folderName: String?
    private(set) var lastSync: Date?
    private(set) var otherDevices: [String]
    private(set) var isSyncing = false
    private(set) var error: String?
    let deviceID: String
    let deviceName: String

    private let store: DailyStore
    private let defaults: UserDefaults
    private var pendingTask: Task<Void, Never>?
    private var rerun = false

    private enum Keys {
        static let deviceID = "syncDeviceID"
        static let bookmark = "syncFolderBookmark"
        static let folderName = "syncFolderName"
        static let lastSync = "syncLastSync"
        static let otherDevices = "syncOtherDevices"
    }

    init(store: DailyStore, defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
        if let id = defaults.string(forKey: Keys.deviceID) {
            deviceID = id
        } else {
            deviceID = UUID().uuidString
            defaults.set(deviceID, forKey: Keys.deviceID)
        }
        deviceName = Self.currentDeviceName
        hasFolder = defaults.data(forKey: Keys.bookmark) != nil
        folderName = defaults.string(forKey: Keys.folderName)
        lastSync = defaults.object(forKey: Keys.lastSync) as? Date
        otherDevices = defaults.stringArray(forKey: Keys.otherDevices) ?? []
        store.onChange = { [weak self] in self?.scheduleSync() }
    }

    func setFolder(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try url.bookmarkData(options: Self.bookmarkCreationOptions, includingResourceValuesForKeys: nil, relativeTo: nil)
            defaults.set(bookmark, forKey: Keys.bookmark)
            defaults.set(url.lastPathComponent, forKey: Keys.folderName)
            folderName = url.lastPathComponent
            hasFolder = true
            error = nil
        } catch {
            self.error = error.localizedDescription
            return
        }
        Task { await syncNow() }
    }

    func scheduleSync(after delay: Duration = .seconds(1.5)) {
        pendingTask?.cancel()
        pendingTask = Task {
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await syncNow()
        }
    }

    func syncNow() async {
        guard hasFolder else { return }
        if isSyncing {
            rerun = true
            return
        }
        isSyncing = true
        defer { isSyncing = false }
        repeat {
            rerun = false
            await performSync()
        } while rerun
    }

    private func performSync() async {
        guard let folder = resolveFolder() else { return }
        let accessed = folder.startAccessingSecurityScopedResource()
        defer { if accessed { folder.stopAccessingSecurityScopedResource() } }
        let deviceID = deviceID
        do {
            let incoming = try await Task.detached { try SyncFiles.readOthers(in: folder, excluding: deviceID) }.value
            for snapshot in incoming.snapshots {
                _ = try store.merge(snapshot)
            }
            otherDevices = incoming.snapshots.map(\.deviceName).sorted()
            defaults.set(otherDevices, forKey: Keys.otherDevices)
            let mine = store.snapshot(deviceID: deviceID, deviceName: deviceName)
            try await Task.detached { try SyncFiles.write(mine, to: folder) }.value
            lastSync = Date()
            defaults.set(lastSync, forKey: Keys.lastSync)
            error = incoming.unreadable.isEmpty ? nil : "Could not read \(incoming.unreadable.joined(separator: ", ")). It may still be downloading."
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func resolveFolder() -> URL? {
        guard let data = defaults.data(forKey: Keys.bookmark) else { return nil }
        var stale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: Self.bookmarkResolutionOptions, relativeTo: nil, bookmarkDataIsStale: &stale)
            if stale {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                if let refreshed = try? url.bookmarkData(options: Self.bookmarkCreationOptions, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    defaults.set(refreshed, forKey: Keys.bookmark)
                }
            }
            return url
        } catch {
            self.error = "The sync folder is no longer available. Choose it again."
            return nil
        }
    }

    #if os(macOS)
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope]
    private static var currentDeviceName: String {
        Host.current().localizedName ?? "Mac"
    }
    #else
    private static let bookmarkCreationOptions: URL.BookmarkCreationOptions = []
    private static let bookmarkResolutionOptions: URL.BookmarkResolutionOptions = []
    private static var currentDeviceName: String {
        UIDevice.current.name
    }
    #endif
}
