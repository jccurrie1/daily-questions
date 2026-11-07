import Foundation
import Observation
import SwiftData

@Model
final class DailyQuestion {
    @Attribute(.unique) private(set) var id: UUID
    fileprivate(set) var text: String
    private(set) var createdDay: String
    fileprivate(set) var archivedDay: String?
    fileprivate(set) var modifiedAt: Date = Date.distantPast

    fileprivate init(text: String, createdDay: String, now: Date) {
        id = UUID()
        self.text = text
        self.createdDay = createdDay
        modifiedAt = now
    }

    fileprivate init(record: QuestionRecord) {
        id = record.id
        text = record.text
        createdDay = record.createdDay
        archivedDay = record.archivedDay
        modifiedAt = record.modifiedAt
    }

    var record: QuestionRecord {
        QuestionRecord(id: id, text: text, createdDay: createdDay, archivedDay: archivedDay, modifiedAt: modifiedAt)
    }
}

struct QuestionRecord: Codable, Equatable, Sendable {
    var id: UUID
    var text: String
    var createdDay: String
    var archivedDay: String?
    var modifiedAt: Date
}

struct AnswerRecord: Codable, Equatable, Sendable {
    var questionID: UUID
    var day: String
    var value: Bool
}

struct SyncSnapshot: Codable, Equatable, Sendable {
    var version = 1
    var deviceID: String
    var deviceName: String
    var exportedAt: Date
    var questions: [QuestionRecord]
    var answers: [AnswerRecord]
}

struct MergeSummary: Equatable, Sendable {
    var addedQuestions = 0
    var updatedQuestions = 0
    var addedAnswers = 0

    var isEmpty: Bool { addedQuestions == 0 && updatedQuestions == 0 && addedAnswers == 0 }
}

@Model
final class DailyAnswer {
    @Attribute(.unique) private(set) var key: String
    private(set) var questionID: UUID
    private(set) var day: String
    private(set) var value: Bool

    fileprivate init(questionID: UUID, day: String, value: Bool) {
        key = Self.key(questionID: questionID, day: day)
        self.questionID = questionID
        self.day = day
        self.value = value
    }

    static func key(questionID: UUID, day: String) -> String {
        "\(questionID.uuidString)/\(day)"
    }

    var record: AnswerRecord {
        AnswerRecord(questionID: questionID, day: day, value: value)
    }
}

enum StoreError: LocalizedError, Equatable {
    case emptyQuestion
    case unknownQuestion
    case archivedQuestion
    case weekend
    case beforeCreation
    case alreadyAnswered

    var errorDescription: String? {
        switch self {
        case .emptyQuestion: "Enter a question."
        case .unknownQuestion: "This question is not available."
        case .archivedQuestion: "This question is archived."
        case .weekend: "Questions can only be answered Monday through Friday."
        case .beforeCreation: "This question was not available on this date."
        case .alreadyAnswered: "This answer is already saved and cannot be changed."
        }
    }
}

enum LocalDay {
    static func calendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return calendar
    }

    static func key(for date: Date, timeZone: TimeZone = .current) -> String {
        let parts = calendar(timeZone: timeZone).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    static func isWeekday(_ date: Date, timeZone: TimeZone = .current) -> Bool {
        (2...6).contains(calendar(timeZone: timeZone).component(.weekday, from: date))
    }

    static func monday(of date: Date, timeZone: TimeZone = .current) -> Date {
        let calendar = calendar(timeZone: timeZone)
        let daysSinceMonday = (calendar.component(.weekday, from: date) + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: date))!
    }

    static func addingDays(_ count: Int, to date: Date, timeZone: TimeZone = .current) -> Date {
        calendar(timeZone: timeZone).date(byAdding: .day, value: count, to: date)!
    }
}

@MainActor
@Observable
final class DailyStore {
    let container: ModelContainer
    private(set) var questions: [DailyQuestion] = []
    private(set) var answers: [DailyAnswer] = []
    var onChange: (@MainActor () -> Void)?
    private let context: ModelContext

    init(inMemory: Bool = false, storageURL: URL? = nil, allowsSave: Bool = true) throws {
        let schema = Schema([DailyQuestion.self, DailyAnswer.self])
        let configuration: ModelConfiguration
        if let storageURL {
            configuration = ModelConfiguration(schema: schema, url: storageURL, allowsSave: allowsSave, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory, allowsSave: allowsSave, cloudKitDatabase: .none)
        }
        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container.mainContext
        context.autosaveEnabled = false
        try refresh()
    }

    func createQuestion(_ text: String, now: Date = Date()) throws -> DailyQuestion {
        let question = DailyQuestion(text: try validText(text), createdDay: LocalDay.key(for: now), now: now)
        context.insert(question)
        try save()
        questions.append(question)
        sortQuestions()
        onChange?()
        return question
    }

    func updateQuestion(_ question: DailyQuestion, text: String, now: Date = Date()) throws {
        try requireActive(question)
        let originalText = question.text
        let originalModifiedAt = question.modifiedAt
        question.text = try validText(text)
        question.modifiedAt = now
        try save { question.text = originalText; question.modifiedAt = originalModifiedAt }
        sortQuestions()
        onChange?()
    }

    func archiveQuestion(_ question: DailyQuestion, now: Date = Date()) throws {
        try requireActive(question)
        question.archivedDay = LocalDay.key(for: now)
        try save { question.archivedDay = nil }
        onChange?()
    }

    func answer(_ question: DailyQuestion, value: Bool, now: Date = Date()) throws {
        try requireActive(question)
        guard LocalDay.isWeekday(now) else { throw StoreError.weekend }
        let day = LocalDay.key(for: now)
        guard day >= question.createdDay else { throw StoreError.beforeCreation }
        guard savedAnswer(for: question, day: day) == nil else { throw StoreError.alreadyAnswered }
        let answer = DailyAnswer(questionID: question.id, day: day, value: value)
        context.insert(answer)
        try save()
        answers.append(answer)
        answers.sort(using: SortDescriptor(\.day))
        onChange?()
    }

    func savedAnswer(for question: DailyQuestion, day: String) -> DailyAnswer? {
        answers.first { $0.questionID == question.id && $0.day == day }
    }

    func snapshot(deviceID: String, deviceName: String, now: Date = Date()) -> SyncSnapshot {
        SyncSnapshot(
            deviceID: deviceID,
            deviceName: deviceName,
            exportedAt: now,
            questions: questions.map(\.record),
            answers: answers.map(\.record)
        )
    }

    func merge(_ snapshot: SyncSnapshot) throws -> MergeSummary {
        var summary = MergeSummary()
        var insertedQuestions: [DailyQuestion] = []
        var insertedAnswers: [DailyAnswer] = []
        var restores: [() -> Void] = []

        for record in snapshot.questions {
            if let question = questions.first(where: { $0.id == record.id }) {
                let originalText = question.text
                let originalModifiedAt = question.modifiedAt
                let originalArchivedDay = question.archivedDay
                var changed = false
                if record.modifiedAt > question.modifiedAt, record.text != question.text {
                    question.text = record.text
                    question.modifiedAt = record.modifiedAt
                    changed = true
                }
                if let remoteArchivedDay = record.archivedDay,
                   question.archivedDay.map({ remoteArchivedDay < $0 }) ?? true {
                    question.archivedDay = remoteArchivedDay
                    changed = true
                }
                if changed {
                    summary.updatedQuestions += 1
                    restores.append {
                        question.text = originalText
                        question.modifiedAt = originalModifiedAt
                        question.archivedDay = originalArchivedDay
                    }
                }
            } else {
                let question = DailyQuestion(record: record)
                context.insert(question)
                insertedQuestions.append(question)
                summary.addedQuestions += 1
            }
        }

        let knownIDs = Set((questions + insertedQuestions).map(\.id))
        let existingKeys = Set(answers.map(\.key))
        for record in snapshot.answers where knownIDs.contains(record.questionID) {
            let key = DailyAnswer.key(questionID: record.questionID, day: record.day)
            guard !existingKeys.contains(key), !insertedAnswers.contains(where: { $0.key == key }) else { continue }
            let answer = DailyAnswer(questionID: record.questionID, day: record.day, value: record.value)
            context.insert(answer)
            insertedAnswers.append(answer)
            summary.addedAnswers += 1
        }

        guard !summary.isEmpty else { return summary }
        try save { restores.forEach { $0() } }
        questions.append(contentsOf: insertedQuestions)
        sortQuestions()
        answers.append(contentsOf: insertedAnswers)
        answers.sort(using: SortDescriptor(\.day))
        return summary
    }

    private func validText(_ text: String) throws -> String {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw StoreError.emptyQuestion }
        return text
    }

    private func requireActive(_ question: DailyQuestion) throws {
        guard questions.contains(where: { $0 === question }) else { throw StoreError.unknownQuestion }
        guard question.archivedDay == nil else { throw StoreError.archivedQuestion }
    }

    private func save(restore: () -> Void = {}) throws {
        do {
            try context.save()
        } catch {
            // Restore loaded model fields before clearing the context's pending changes.
            restore()
            context.rollback()
            throw error
        }
    }

    private func refresh() throws {
        questions = try context.fetch(FetchDescriptor<DailyQuestion>(sortBy: [SortDescriptor(\.createdDay), SortDescriptor(\.text)]))
        answers = try context.fetch(FetchDescriptor<DailyAnswer>(sortBy: [SortDescriptor(\.day)]))
    }

    private func sortQuestions() {
        questions.sort(using: [SortDescriptor(\.createdDay), SortDescriptor(\.text)])
    }
}
