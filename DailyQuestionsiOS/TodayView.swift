import SwiftUI

struct TodayView: View {
    let store: DailyStore
    let sync: SyncCoordinator
    @State private var error: String?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { timeline in
                let now = timeline.date
                let day = LocalDay.key(for: now)
                let active = store.questions.filter { $0.archivedDay == nil && $0.createdDay <= day }
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if !LocalDay.isWeekday(now) {
                            message("It's the weekend. Take it easy.", detail: "Questions return Monday.")
                        } else if active.isEmpty {
                            message("No active questions", detail: "Add one in Questions.")
                        } else {
                            completion(active: active, day: day)
                            VStack(spacing: 10) {
                                ForEach(active) { question in
                                    card(question, saved: store.savedAnswer(for: question, day: day))
                                }
                            }
                        }
                        if let error {
                            Text(error).font(.callout).foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .navigationTitle("Today")
                .navigationSubtitle(now.formatted(MobileLayout.dateFormat.weekday(.abbreviated).month(.abbreviated).day().year()))
            }
            .background(Palette.background)
            .settingsToolbar(sync)
        }
    }

    private func message(_ title: String, detail: String) -> some View {
        VStack(spacing: 8) {
            Text(title).foregroundStyle(.secondary)
            Text(detail).font(.callout).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .multilineTextAlignment(.center)
    }

    private func completion(active: [DailyQuestion], day: String) -> some View {
        let count = active.filter { store.savedAnswer(for: $0, day: day) != nil }.count
        return HStack(spacing: 14) {
            Text("\(count) of \(active.count) answered").font(.callout).foregroundStyle(.secondary)
            ProgressView(value: Double(count), total: Double(active.count))
                .tint(Palette.ink)
                .accessibilityLabel("Answered questions")
            Text("\(Int(Double(count) / Double(active.count) * 100))%")
                .font(.callout).foregroundStyle(.secondary).monospacedDigit()
        }
    }

    private func card(_ question: DailyQuestion, saved: DailyAnswer?) -> some View {
        HStack(spacing: 12) {
            Text(question.text).frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 8) {
                AnswerButton(value: true, question: question, saved: saved, size: 44, fontSize: 17) { answer(question, value: true) }
                AnswerButton(value: false, question: question, saved: saved, size: 44, fontSize: 17) { answer(question, value: false) }
                SavedLock(saved: saved != nil)
            }
        }
        .padding(.vertical, 16)
        .padding(.leading, 16)
        .padding(.trailing, 14)
        .mobileCard()
    }

    private func answer(_ question: DailyQuestion, value: Bool) {
        do {
            try store.answer(question, value: value)
            error = nil
        } catch { self.error = error.localizedDescription }
    }
}
