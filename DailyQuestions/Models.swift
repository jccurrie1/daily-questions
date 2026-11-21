import Foundation
import Observation
import SwiftData

@Model
final class DailyQuestion {
    @Attribute(.unique) private(set) var id: UUID
    fileprivate(set) var text: String
    private(set) var createdDay: String
    fileprivate(set) var archivedDay: String?

    fileprivate init(text: String, createdDay: String) {
        id = UUID()
        self.text = text
        self.createdDay = createdDay
    }
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
        let question = DailyQuestion(text: try validText(text), createdDay: LocalDay.key(for: now))
        context.insert(question)
        try save()
        questions.append(question)
        sortQuestions()
        return question
    }

    func updateQuestion(_ question: DailyQuestion, text: String) throws {
        try requireActive(question)
        let originalText = question.text
        question.text = try validText(text)
        try save { question.text = originalText }
        sortQuestions()
    }

    func archiveQuestion(_ question: DailyQuestion, now: Date = Date()) throws {
        try requireActive(question)
        question.archivedDay = LocalDay.key(for: now)
        try save { question.archivedDay = nil }
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
    }

    func savedAnswer(for question: DailyQuestion, day: String) -> DailyAnswer? {
        answers.first { $0.questionID == question.id && $0.day == day }
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
