import Charts
import SwiftUI

struct QuestionPerformanceView: View {
    let question: DailyQuestion
    let store: DailyStore
    var onBack: (() -> Void)? = nil

    @State private var selectedWeek: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let onBack {
                        Button(action: onBack) {
                            Label("Questions", systemImage: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(question.text)
                            .font(.system(size: 28, weight: .semibold))
                            .textSelection(.enabled)
                        if question.archivedDay != nil {
                            Text("Archived")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Palette.selection, in: Capsule())
                        }
                    }

                    activityOverview(today: context.date)

                    weekNavigation(today: context.date)
                        .frame(maxWidth: .infinity)

                    VStack(alignment: .leading, spacing: 20) {
                        Text("Weekly answers")
                            .font(.title3.weight(.semibold))

                        weeklyChart(today: context.date)
                            .frame(height: 245)

                        if !(0..<5).contains(where: { index in
                            store.savedAnswer(for: question, day: dayKey(index, today: context.date)) != nil
                        }) {
                            Text("No answers recorded for this week.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Palette.border, lineWidth: 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .onChange(of: question.id) { _, _ in
            selectedWeek = nil
        }
    }

    private func activityOverview(today: Date) -> some View {
        let days = Self.activityDates(today: today)
        let start = days[0]
        let end = days[19]
        let yesCount = days.filter {
            store.savedAnswer(for: question, day: LocalDay.key(for: $0))?.value == true
        }.count

        return VStack(alignment: .leading, spacing: 14) {
            Text("Activity · last four weeks")
                .font(.title3.weight(.semibold))
            Text("\(start.formatted(dateFormat.month(.abbreviated).day().year())) – \(end.formatted(dateFormat.month(.abbreviated).day().year()))")
                .font(.callout)
                .foregroundStyle(.secondary)

            Grid(horizontalSpacing: 12, verticalSpacing: 10) {
                GridRow {
                    Color.clear.frame(width: 64, height: 1).accessibilityHidden(true)
                    ForEach(["Mon", "Tue", "Wed", "Thu", "Fri"], id: \.self) { weekday in
                        Text(weekday)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 44)
                    }
                }
                ForEach(0..<4, id: \.self) { week in
                    GridRow {
                        Text(days[week * 5].formatted(dateFormat.month(.abbreviated).day()))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .frame(width: 64, alignment: .trailing)
                        ForEach(0..<5, id: \.self) { weekday in
                            let date = days[week * 5 + weekday]
                            let day = LocalDay.key(for: date)
                            let status = answerStatus(day: day, today: today)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(status == "Yes" ? Palette.ink : status == "No answer due" ? Palette.selection : Palette.surface)
                                .frame(width: 44, height: 44)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(status == "Yes" ? Palette.ink : Palette.border, lineWidth: 1)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(date.formatted(dateFormat.weekday(.wide).month(.wide).day().year()))
                                .accessibilityValue(status)
                                .help("\(date.formatted(dateFormat.weekday(.wide).month(.wide).day().year())): \(status)")
                                .focusable()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)

            Text("\(yesCount) Yes \(yesCount == 1 ? "day" : "days")")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.border, lineWidth: 1)
        }
    }

    static func activityDates(today: Date, timeZone: TimeZone = .current) -> [Date] {
        let start = LocalDay.addingDays(-21, to: LocalDay.monday(of: today, timeZone: timeZone), timeZone: timeZone)
        return (0..<4).flatMap { week in
            (0..<5).map { weekday in
                LocalDay.addingDays(week * 7 + weekday, to: start, timeZone: timeZone)
            }
        }
    }

    private func weekNavigation(today: Date) -> some View {
        HStack(spacing: 18) {
            Button {
                selectedWeek = LocalDay.key(for: LocalDay.addingDays(-7, to: weekStart(today: today)))
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Previous week")
            .help("Previous week")

            Text(weekRange(today: today))
                .font(.body.weight(.medium))
                .monospacedDigit()
                .frame(minWidth: 195)
                .accessibilityLabel("Week of \(weekRange(today: today))")

            Button {
                let next = LocalDay.key(for: LocalDay.addingDays(7, to: weekStart(today: today)))
                selectedWeek = next >= LocalDay.key(for: LocalDay.monday(of: today)) ? nil : next
            } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .disabled(LocalDay.key(for: weekStart(today: today)) >= LocalDay.key(for: LocalDay.monday(of: today)))
            .accessibilityLabel("Next week")
            .help("Next week")
        }
    }

    private func weeklyChart(today: Date) -> some View {
        Chart {
            ForEach(0..<5, id: \.self) { index in
                if let answer = store.savedAnswer(for: question, day: dayKey(index, today: today)) {
                    PointMark(
                        x: .value("Weekday", Double(index)),
                        y: .value("Answer", answer.value ? 1 : 0)
                    )
                    .symbolSize(100)
                    .foregroundStyle(Palette.ink)
                    .accessibilityLabel(dayDate(index, today: today).formatted(dateFormat.weekday(.wide).month(.wide).day().year()))
                    .accessibilityValue(answer.value ? "Yes" : "No")
                }
            }
        }
        .chartXScale(domain: -0.5...4.5)
        .chartYScale(domain: -0.5...1.5)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 1]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Palette.border)
                AxisValueLabel {
                    Text(value.as(Int.self) == 1 ? "Yes" : "No")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: [0, 1, 2, 3, 4]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Palette.border)
                AxisValueLabel(anchor: .top) {
                    if let index = value.as(Int.self) {
                        VStack(spacing: 8) {
                            Text(dayDate(index, today: today).formatted(dateFormat.weekday(.abbreviated).day()))
                                .foregroundStyle(.secondary)
                            Text(answerLabel(index, today: today))
                                .foregroundStyle(store.savedAnswer(for: question, day: dayKey(index, today: today)) == nil ? Color.secondary : Palette.ink)
                        }
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Weekly answers, \(weekRange(today: today))")
        .accessibilityValue((0..<5).map { index in
            "\(dayDate(index, today: today).formatted(dateFormat.weekday(.wide).month(.wide).day().year())): \(answerLabel(index, today: today))"
        }.joined(separator: ". "))
    }

    // Keep a calendar date for history; an absolute midnight can become Sunday after a time-zone change.
    private func weekStart(today: Date) -> Date {
        Self.startOfWeek(selectedWeek: selectedWeek, today: today)
    }

    static func startOfWeek(selectedWeek: String?, today: Date, timeZone: TimeZone = .current) -> Date {
        guard let selectedWeek else { return LocalDay.monday(of: today, timeZone: timeZone) }
        let parts = selectedWeek.split(separator: "-").map { Int($0)! }
        return LocalDay.calendar(timeZone: timeZone).date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))!
    }

    private func dayDate(_ index: Int, today: Date) -> Date {
        LocalDay.addingDays(index, to: weekStart(today: today))
    }

    private func dayKey(_ index: Int, today: Date) -> String {
        LocalDay.key(for: dayDate(index, today: today))
    }

    private func answerLabel(_ index: Int, today: Date) -> String {
        answerStatus(day: dayKey(index, today: today), today: today)
    }

    private func answerStatus(day: String, today: Date) -> String {
        if let answer = store.savedAnswer(for: question, day: day) {
            return answer.value ? "Yes" : "No"
        }
        if day > LocalDay.key(for: today) || day < question.createdDay ||
            question.archivedDay.map({ day > $0 }) == true {
            return "No answer due"
        }
        return "Not answered"
    }

    private var dateFormat: Date.FormatStyle {
        Date.FormatStyle(calendar: LocalDay.calendar(), timeZone: .current)
    }

    private func weekRange(today: Date) -> String {
        let start = weekStart(today: today)
        let end = LocalDay.addingDays(4, to: start)
        return "\(start.formatted(dateFormat.month(.abbreviated).day())) – \(end.formatted(dateFormat.month(.abbreviated).day().year()))"
    }
}
