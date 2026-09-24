import Foundation

@main
struct StoreChecks {
    @MainActor
    static func main() throws {
        try checkDates()
        try checkStore(inMemory: true)
        try checkPersistence()
        try checkFailedSaves()
        print("Store checks passed: dates, validation, immutable answers, archiving, disk persistence, and failed-save rollback/retry.")
    }

    @MainActor
    static func checkFailedSaves() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("DailyQuestions-save-failure-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("questions.store")
        let monday = date(2026, 9, 21)
        do {
            let writable = try DailyStore(storageURL: url)
            _ = try writable.createQuestion("Original wording", now: monday)
        }
        do {
            let readOnly = try DailyStore(storageURL: url, allowsSave: false)
            let question = readOnly.questions[0]
            expectSaveFailure { try readOnly.answer(question, value: true, now: monday) }
            precondition(readOnly.answers.isEmpty)
            precondition(readOnly.savedAnswer(for: question, day: "2026-09-21") == nil)
            precondition(!readOnly.container.mainContext.hasChanges)
            expectSaveFailure { try readOnly.answer(question, value: false, now: monday) }
            expectSaveFailure { try readOnly.updateQuestion(question, text: "Unsaved wording") }
            precondition(question.text == "Original wording")
            precondition(!readOnly.container.mainContext.hasChanges)
            expectSaveFailure { try readOnly.archiveQuestion(question, now: monday) }
            precondition(question.archivedDay == nil)
            precondition(!readOnly.container.mainContext.hasChanges)
            expectSaveFailure { _ = try readOnly.createQuestion("Unsaved question", now: monday) }
            precondition(readOnly.questions.count == 1 && readOnly.answers.isEmpty)
            precondition(!readOnly.container.mainContext.hasChanges)
        }
        let retry = try DailyStore(storageURL: url)
        let question = retry.questions[0]
        precondition(question.text == "Original wording" && question.archivedDay == nil)
        precondition(retry.answers.isEmpty)
        try retry.answer(question, value: false, now: monday)
        precondition(retry.savedAnswer(for: question, day: "2026-09-21")?.value == false)
        let reopened = try DailyStore(storageURL: url)
        precondition(reopened.answers.count == 1 && reopened.answers[0].value == false)
    }

    @MainActor
    static func expectSaveFailure(operation: () throws -> Void) {
        do {
            try operation()
            preconditionFailure("Expected the read-only store to reject saving.")
        } catch {
            precondition(!(error is StoreError), "Expected a storage error, got \(error)")
        }
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, timeZone: TimeZone = .current) -> Date {
        LocalDay.calendar(timeZone: timeZone).date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    static func checkDates() throws {
        let detroit = TimeZone(identifier: "America/Detroit")!
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!
        let instant = date(2026, 9, 23, hour: 23, timeZone: detroit)
        let savedDay = LocalDay.key(for: instant, timeZone: detroit)
        precondition(savedDay == "2026-09-23")
        precondition(LocalDay.key(for: instant, timeZone: tokyo) == "2026-09-24")
        precondition(savedDay == "2026-09-23", "Saved date keys must not move across time zones.")
        let midnight = date(2026, 9, 24, hour: 0, timeZone: detroit)
        precondition(LocalDay.key(for: midnight.addingTimeInterval(-1), timeZone: detroit) == "2026-09-23")
        precondition(LocalDay.key(for: midnight, timeZone: detroit) == "2026-09-24")
        let sunday = date(2026, 9, 27, timeZone: detroit)
        precondition(!LocalDay.isWeekday(sunday, timeZone: detroit))
        precondition(!LocalDay.isWeekday(date(2026, 9, 26, timeZone: detroit), timeZone: detroit))
        precondition(LocalDay.isWeekday(date(2026, 9, 25, timeZone: detroit), timeZone: detroit))
        precondition(LocalDay.key(for: LocalDay.monday(of: sunday, timeZone: detroit), timeZone: detroit) == "2026-09-21")
        let dstEve = date(2026, 3, 7, timeZone: detroit)
        let dstDay = LocalDay.addingDays(1, to: dstEve, timeZone: detroit)
        precondition(dstDay.timeIntervalSince(dstEve) == 23 * 60 * 60)
        precondition(LocalDay.key(for: dstDay, timeZone: detroit) == "2026-03-08")
        let newYear = LocalDay.monday(of: date(2027, 1, 1, timeZone: detroit), timeZone: detroit)
        precondition(LocalDay.key(for: newYear, timeZone: detroit) == "2026-12-28")
    }

    @MainActor
    static func checkStore(inMemory: Bool, storageURL: URL? = nil) throws {
        let store = try DailyStore(inMemory: inMemory, storageURL: storageURL)
        let monday = date(2026, 9, 21)
        try expect(.emptyQuestion) { _ = try store.createQuestion(" \n ", now: monday) }
        precondition(store.questions.isEmpty)
        let question = try store.createQuestion("  Work on app? \n", now: monday)
        let other = try store.createQuestion("Read?", now: monday)
        let id = question.id
        precondition(question.text == "Work on app?")
        precondition(store.savedAnswer(for: question, day: "2026-09-21") == nil)
        try store.answer(question, value: true, now: monday)
        try store.answer(other, value: false, now: monday)
        precondition(store.answers.count == 2)
        precondition(store.savedAnswer(for: question, day: "2026-09-21")?.value == true)
        precondition(store.savedAnswer(for: other, day: "2026-09-21")?.value == false)
        try expect(.alreadyAnswered) { try store.answer(question, value: false, now: monday) }
        precondition(store.answers.count == 2)
        precondition(store.savedAnswer(for: question, day: "2026-09-21")?.value == true)
        try expect(.emptyQuestion) { try store.updateQuestion(question, text: "\t") }
        precondition(question.text == "Work on app?")
        try store.updateQuestion(question, text: "Build app?")
        precondition(question.id == id && question.text == "Build app?")
        precondition(store.savedAnswer(for: question, day: "2026-09-21")?.value == true)
        try expect(.beforeCreation) { try store.answer(question, value: false, now: date(2026, 9, 18)) }
        try expect(.weekend) { try store.answer(question, value: false, now: date(2026, 9, 26)) }
        try expect(.weekend) { try store.answer(question, value: false, now: date(2026, 9, 27)) }
        try store.answer(question, value: false, now: date(2026, 9, 22))
        precondition(store.savedAnswer(for: question, day: "2026-09-22")?.value == false)
        try store.archiveQuestion(question, now: date(2026, 9, 22))
        precondition(question.archivedDay == "2026-09-22")
        precondition(store.questions.count == 2 && store.answers.count == 3)
        try expect(.archivedQuestion) { try store.answer(question, value: true, now: date(2026, 9, 23)) }
        try expect(.archivedQuestion) { try store.updateQuestion(question, text: "Changed") }
        let foreignStore = try DailyStore(inMemory: true)
        let foreignQuestion = try foreignStore.createQuestion("Foreign", now: monday)
        try expect(.unknownQuestion) { try store.answer(foreignQuestion, value: true, now: monday) }
    }

    @MainActor
    static func checkPersistence() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("DailyQuestions-checks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("questions.store")
        try checkStore(inMemory: false, storageURL: url)
        let reopened = try DailyStore(storageURL: url)
        precondition(reopened.questions.count == 2 && reopened.answers.count == 3)
        let archived = reopened.questions.first { $0.text == "Build app?" }!
        precondition(archived.archivedDay == "2026-09-22")
        precondition(reopened.savedAnswer(for: archived, day: "2026-09-21")?.value == true)
        precondition(reopened.savedAnswer(for: archived, day: "2026-09-22")?.value == false)
        let active = reopened.questions.first { $0.text == "Read?" }!
        try expect(.alreadyAnswered) { try reopened.answer(active, value: true, now: date(2026, 9, 21)) }
        precondition(reopened.savedAnswer(for: active, day: "2026-09-21")?.value == false)
        precondition(FileManager.default.fileExists(atPath: url.path))
    }

    @MainActor
    static func expect(_ expected: StoreError, operation: () throws -> Void) throws {
        do {
            try operation()
            preconditionFailure("Expected \(expected)")
        } catch let error as StoreError {
            precondition(error == expected, "Expected \(expected), got \(error)")
        }
    }
}
