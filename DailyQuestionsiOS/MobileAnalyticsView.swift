import SwiftUI

struct MobileAnalyticsView: View {
    let store: DailyStore
    let sync: SyncCoordinator

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let questions = store.questions.filter { $0.archivedDay == nil }
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if questions.isEmpty {
                            Text("No active questions")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 200)
                        } else {
                            Text("Last four weeks")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                            ForEach(questions) { question in
                                NavigationLink(value: question.id) {
                                    row(question, today: context.date)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Open analytics")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .background(Palette.background)
            .navigationTitle("Analytics")
            .settingsToolbar(sync)
            .navigationDestination(for: UUID.self) { id in
                if let question = store.questions.first(where: { $0.id == id }) {
                    MobileReportView(question: question, store: store)
                }
            }
        }
    }

    private func row(_ question: DailyQuestion, today: Date) -> some View {
        let days = QuestionPerformanceView.activityDates(today: today)
        let yesCount = days.filter { store.savedAnswer(for: question, day: LocalDay.key(for: $0))?.value == true }.count
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(question.text)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                Text("\(yesCount) Yes \(yesCount == 1 ? "day" : "days")")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .mobileCard()
        .contentShape(MobileLayout.cardShape)
    }
}
