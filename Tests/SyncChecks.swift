import Foundation

@main
struct SyncChecks {
    @MainActor
    static func main() throws {
        try checkMerge()
        try checkFolderExchange()
        print("Sync checks passed: answer union, newer wording wins, one-way archive, unknown answers skipped, failed merge rollback, and folder exchange.")
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        LocalDay.calendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @MainActor
    static func checkMerge() throws {
        let monday = date(2026, 9, 21)
        let tuesday = date(2026, 9, 22)
        let mac = try DailyStore(inMemory: true)
        let phone = try DailyStore(inMemory: true)
        var changes = 0
        mac.onChange = { changes += 1 }

        let shared = try mac.createQuestion("Worked on my app?", now: monday)
        let macOnly = try mac.createQuestion("Reviewed PRs?", now: monday)
        try mac.answer(shared, value: true, now: monday)
        precondition(changes == 3)

        let first = try phone.merge(mac.snapshot(deviceID: "mac", deviceName: "Mac"))
        precondition(first == MergeSummary(addedQuestions: 2, updatedQuestions: 0, addedAnswers: 1))
        precondition(phone.questions.count == 2 && phone.answers.count == 1)
        let phoneShared = phone.questions.first { $0.id == shared.id }!
        precondition(phoneShared.text == "Worked on my app?" && phoneShared.createdDay == "2026-09-21")
        precondition(phone.savedAnswer(for: phoneShared, day: "2026-09-21")?.value == true)
        let repeated = try phone.merge(mac.snapshot(deviceID: "mac", deviceName: "Mac"))
        precondition(repeated.isEmpty)

        try phone.answer(phoneShared, value: false, now: tuesday)
        try phone.updateQuestion(phoneShared, text: "Worked on the app?", now: tuesday)
        let phoneOnly = try phone.createQuestion("Exercised?", now: tuesday)
        try phone.answer(phoneOnly, value: true, now: tuesday)
        let back = try mac.merge(phone.snapshot(deviceID: "phone", deviceName: "iPhone"))
        precondition(back == MergeSummary(addedQuestions: 1, updatedQuestions: 1, addedAnswers: 2))
        precondition(shared.text == "Worked on the app?")
        precondition(mac.savedAnswer(for: shared, day: "2026-09-21")?.value == true)
        precondition(mac.savedAnswer(for: shared, day: "2026-09-22")?.value == false)
        precondition(mac.questions.contains { $0.id == phoneOnly.id && $0.text == "Exercised?" })
        precondition(changes == 3, "Merging must not count as a local change.")

        try mac.updateQuestion(shared, text: "Newer local wording", now: date(2026, 9, 23))
        let olderRemote = try mac.merge(phone.snapshot(deviceID: "phone", deviceName: "iPhone"))
        precondition(olderRemote.isEmpty)
        precondition(shared.text == "Newer local wording", "An older remote edit must not replace newer local wording.")
        _ = try phone.merge(mac.snapshot(deviceID: "mac", deviceName: "Mac"))
        precondition(phoneShared.text == "Newer local wording")
        precondition(phoneShared.modifiedAt == shared.modifiedAt)

        try phone.archiveQuestion(phoneShared, now: date(2026, 9, 24))
        _ = try mac.merge(phone.snapshot(deviceID: "phone", deviceName: "iPhone"))
        precondition(shared.archivedDay == "2026-09-24")
        try mac.archiveQuestion(macOnly, now: date(2026, 9, 25))
        var earlier = phone.snapshot(deviceID: "phone", deviceName: "iPhone")
        earlier.questions = earlier.questions.map { record in
            var record = record
            if record.id == macOnly.id { record.archivedDay = "2026-09-23" }
            return record
        }
        _ = try mac.merge(earlier)
        precondition(macOnly.archivedDay == "2026-09-23", "The earlier archive day wins.")
        let unknownAnswer = try mac.merge(SyncSnapshot(deviceID: "x", deviceName: "x", exportedAt: monday, questions: [], answers: [AnswerRecord(questionID: UUID(), day: "2026-09-21", value: true)]))
        precondition(unknownAnswer.isEmpty)

        let strayID = UUID()
        let stray = SyncSnapshot(deviceID: "y", deviceName: "y", exportedAt: monday, questions: [
            QuestionRecord(id: strayID, text: "", createdDay: "2026-09-21", archivedDay: nil, modifiedAt: monday),
        ], answers: [AnswerRecord(questionID: strayID, day: "2026-09-21", value: true)])
        let before = mac.questions.count
        _ = try mac.merge(stray)
        precondition(mac.questions.count == before + 1 && mac.savedAnswer(for: mac.questions.first { $0.id == strayID }!, day: "2026-09-21") != nil)
    }

    @MainActor
    static func checkFolderExchange() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("DailyQuestions-sync-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appendingPathComponent("readonly.store")
        let folder = directory.appendingPathComponent("Sync", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try "not json".write(to: folder.appendingPathComponent("junk.json"), atomically: true, encoding: .utf8)
        try "ignored".write(to: folder.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)

        let monday = date(2026, 9, 21)
        let mac = try DailyStore(inMemory: true)
        let question = try mac.createQuestion("Worked on my app?", now: monday)
        try mac.answer(question, value: true, now: monday)
        try SyncFiles.write(mac.snapshot(deviceID: "mac", deviceName: "Mac", now: monday), to: folder)
        precondition(FileManager.default.fileExists(atPath: folder.appendingPathComponent("mac.json").path))

        let ownOnly = try SyncFiles.readOthers(in: folder, excluding: "mac", downloadTimeout: 0)
        precondition(ownOnly.snapshots.isEmpty && ownOnly.unreadable == ["junk.json"])

        let phone = try DailyStore(inMemory: true)
        let incoming = try SyncFiles.readOthers(in: folder, excluding: "phone", downloadTimeout: 0)
        precondition(incoming.snapshots.count == 1 && incoming.snapshots[0].deviceName == "Mac")
        precondition(incoming.snapshots[0].exportedAt == monday)
        _ = try phone.merge(incoming.snapshots[0])
        let phoneQuestion = phone.questions[0]
        precondition(phoneQuestion.id == question.id && phoneQuestion.modifiedAt == question.modifiedAt)
        try phone.answer(phoneQuestion, value: false, now: date(2026, 9, 22))
        try SyncFiles.write(phone.snapshot(deviceID: "phone", deviceName: "iPhone"), to: folder)

        let round = try SyncFiles.readOthers(in: folder, excluding: "mac", downloadTimeout: 0)
        precondition(round.snapshots.map(\.deviceName) == ["iPhone"])
        _ = try mac.merge(round.snapshots[0])
        precondition(mac.savedAnswer(for: question, day: "2026-09-22")?.value == false)

        do {
            let writable = try DailyStore(storageURL: storeURL)
            _ = try writable.createQuestion("Local", now: monday)
        }
        let readOnly = try DailyStore(storageURL: storeURL, allowsSave: false)
        do {
            _ = try readOnly.merge(mac.snapshot(deviceID: "mac", deviceName: "Mac"))
            preconditionFailure("Expected the read-only store to reject the merge.")
        } catch {
            precondition(readOnly.questions.count == 1 && readOnly.answers.isEmpty)
            precondition(!readOnly.container.mainContext.hasChanges)
        }
    }
}
