import SwiftUI

struct MenuPanel: View {
    let store: DailyStore
    @State private var error: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let now = timeline.date
            let day = LocalDay.key(for: now)
            let active = store.questions.filter { $0.archivedDay == nil && $0.createdDay <= day }
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today").font(.title2.bold())
                    Text(now, format: Date.FormatStyle(calendar: LocalDay.calendar(), timeZone: .current)
                        .weekday(.abbreviated).month(.abbreviated).day().year())
                        .foregroundStyle(.secondary)
                }
                if !LocalDay.isWeekday(now) {
                    Text("No questions on weekends").foregroundStyle(.secondary).padding(.vertical, 20)
                } else if active.isEmpty {
                    Text("No active questions").foregroundStyle(.secondary).padding(.vertical, 20)
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(active) { question in
                                let saved = store.savedAnswer(for: question, day: day)
                                HStack(spacing: 12) {
                                    Text(question.text).frame(maxWidth: .infinity, alignment: .leading)
                                    HStack(spacing: 8) {
                                        answerButton("y", value: true, question: question, saved: saved)
                                        answerButton("n", value: false, question: question, saved: saved)
                                        Image(systemName: "lock.fill")
                                            .font(.caption).foregroundStyle(.secondary)
                                            .opacity(saved == nil ? 0 : 1)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .padding(14)
                                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.border.opacity(0.7), lineWidth: 1))
                            }
                        }
                    }
                    .frame(height: min(CGFloat(active.count) * 68, 400))
                    Divider()
                    let count = active.filter { store.savedAnswer(for: $0, day: day) != nil }.count
                    HStack(spacing: 16) {
                        Text("\(count) of \(active.count) answered").font(.callout).foregroundStyle(.secondary)
                        ProgressView(value: Double(count), total: Double(active.count))
                            .tint(Palette.ink)
                            .accessibilityLabel("Answered questions")
                        Text("\(Int(Double(count) / Double(active.count) * 100))%")
                            .font(.callout).foregroundStyle(.secondary).monospacedDigit()
                    }
                }
                if let error { Text(error).font(.callout).foregroundStyle(.red) }
            }
            .padding(20)
            .frame(width: 460)
            .background(Palette.background)
        }
    }

    private func answerButton(_ label: String, value: Bool, question: DailyQuestion, saved: DailyAnswer?) -> some View {
        Button {
            do {
                // Read the clock at the click, not when the panel last rendered.
                try store.answer(question, value: value)
                error = nil
            } catch { self.error = error.localizedDescription }
        } label: {
            Text(label).font(.system(size: 16, weight: .medium))
                .frame(width: 34, height: 34)
                .foregroundStyle(saved?.value == value ? .white : Palette.ink)
                .background(saved?.value == value ? Palette.ink : Color(white: 0.91), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(AnswerBubbleStyle())
        .disabled(saved != nil)
        .accessibilityLabel("\(value ? "Yes" : "No") — \(question.text)")
        .accessibilityValue(saved.map { "Saved \($0.value ? "Yes" : "No"). Cannot be changed." } ?? "Not answered")
        .help(saved == nil ? (value ? "Answer Yes" : "Answer No") : "Saved answers cannot be changed")
    }
}

private struct AnswerBubbleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.75 : 1)
    }
}
