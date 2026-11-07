import SwiftUI

struct MobileReportView: View {
    let question: DailyQuestion
    let store: DailyStore
    @State private var selectedWeek: String?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let today = context.date
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(question.text)
                            .font(.system(size: 26, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if question.archivedDay != nil {
                            Text("Archived")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Palette.selection, in: Capsule())
                        }
                    }
                    .padding(.bottom, 8)
                    fourWeeks(today: today)
                    weekDetail(today: today)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .background(Palette.background)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func fourWeeks(today: Date) -> some View {
        let days = QuestionPerformanceView.activityDates(today: today)
        let yesCount = days.filter { status(day: LocalDay.key(for: $0), today: today) == "Yes" }.count
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Four weeks").font(.headline)
                Spacer()
                Text("\(days[0].formatted(MobileLayout.dateFormat.month(.abbreviated).day())) – \(days[19].formatted(MobileLayout.dateFormat.month(.abbreviated).day()))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Color.clear.frame(width: 48, height: 1).accessibilityHidden(true)
                    ForEach(0..<5, id: \.self) { weekday in
                        Text(["M", "T", "W", "T", "F"][weekday])
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: 44)
                    }
                }
                .accessibilityHidden(true)
                ForEach(0..<4, id: \.self) { week in
                    GridRow {
                        Text(days[week * 5].formatted(MobileLayout.dateFormat.month(.abbreviated).day()))
                            .font(.caption)
                            .foregroundStyle(week == 3 ? Palette.ink : .secondary)
                            .fontWeight(week == 3 ? .semibold : .regular)
                            .frame(width: 48, alignment: .leading)
                            .accessibilityHidden(true)
                        ForEach(0..<5, id: \.self) { weekday in
                            let date = days[week * 5 + weekday]
                            let status = status(day: LocalDay.key(for: date), today: today)
                            cell(status: status)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(date.formatted(MobileLayout.dateFormat.weekday(.wide).month(.wide).day().year()))
                                .accessibilityValue(status)
                        }
                    }
                }
            }
            HStack(spacing: 16) {
                legendItem("Yes") { RoundedRectangle(cornerRadius: 3).fill(Palette.ink) }
                legendItem("No") { RoundedRectangle(cornerRadius: 3).fill(Palette.selection) }
                legendItem("Not answered") {
                    RoundedRectangle(cornerRadius: 3).strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2]))
                }
            }
            .accessibilityHidden(true)
            Text("\(yesCount) Yes \(yesCount == 1 ? "day" : "days")")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .mobileCard()
    }

    private func cell(status: String) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(status == "Yes" ? Palette.ink : (status == "No" ? Palette.selection : Palette.selection.opacity(0.35)))
            .overlay {
                if status == "Not answered" {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 44)
    }

    private func weekDetail(today: Date) -> some View {
        let statuses = (0..<5).map { status(day: LocalDay.key(for: dayDate($0, today: today)), today: today) }
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                weekButton("chevron.left", label: "Previous week") {
                    selectedWeek = LocalDay.key(for: LocalDay.addingDays(-7, to: weekStart(today: today)))
                }
                VStack(spacing: 2) {
                    Text("Week in detail").font(.headline)
                    Text(weekRange(today: today))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                weekButton("chevron.right", label: "Next week") {
                    let next = LocalDay.key(for: LocalDay.addingDays(7, to: weekStart(today: today)))
                    selectedWeek = next >= LocalDay.key(for: LocalDay.monday(of: today)) ? nil : next
                }
                .disabled(LocalDay.key(for: weekStart(today: today)) >= LocalDay.key(for: LocalDay.monday(of: today)))
            }
            HStack(alignment: .top, spacing: 6) {
                ForEach(0..<5, id: \.self) { index in
                    let date = dayDate(index, today: today)
                    let status = statuses[index]
                    VStack(spacing: 8) {
                        Text(date.formatted(MobileLayout.dateFormat.weekday(.abbreviated).day()))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        dayCell(status: status)
                        Text(status)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(date.formatted(MobileLayout.dateFormat.weekday(.wide).month(.wide).day().year()))
                    .accessibilityValue(status)
                }
            }
            Text(summary(statuses))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .mobileCard()
    }

    private func weekButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.footnote.weight(.semibold))
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .accessibilityLabel(label)
    }

    private func dayCell(status: String) -> some View {
        let saved = status == "Yes" || status == "No"
        return Circle()
            .fill(status == "Yes" ? Palette.ink : (status == "No" ? Palette.selection : .clear))
            .frame(width: 40, height: 40)
            .overlay {
                if status == "Not answered" {
                    Circle().strokeBorder(Palette.border, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
            }
            .overlay {
                if saved {
                    Text(status == "Yes" ? "y" : "n")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(status == "Yes" ? Palette.onInk : Palette.ink)
                }
            }
    }

    private func legendItem(_ label: String, @ViewBuilder swatch: () -> some View) -> some View {
        HStack(spacing: 6) {
            swatch().frame(width: 12, height: 12)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func summary(_ statuses: [String]) -> String {
        let yes = statuses.filter { $0 == "Yes" }.count
        let no = statuses.filter { $0 == "No" }.count
        let missing = statuses.filter { $0 == "Not answered" }.count
        if yes == 0, no == 0, missing == 0 { return "No answers due this week." }
        var parts: [String] = []
        if yes > 0 { parts.append("\(yes) Yes") }
        if no > 0 { parts.append("\(no) No") }
        if missing > 0 { parts.append("\(missing) not answered") }
        return parts.joined(separator: ", ") + "."
    }

    private func status(day: String, today: Date) -> String {
        if let answer = store.savedAnswer(for: question, day: day) {
            return answer.value ? "Yes" : "No"
        }
        if day > LocalDay.key(for: today) || day < question.createdDay ||
            question.archivedDay.map({ day > $0 }) == true {
            return "No answer due"
        }
        return "Not answered"
    }

    private func weekStart(today: Date) -> Date {
        QuestionPerformanceView.startOfWeek(selectedWeek: selectedWeek, today: today)
    }

    private func dayDate(_ index: Int, today: Date) -> Date {
        LocalDay.addingDays(index, to: weekStart(today: today))
    }

    private func weekRange(today: Date) -> String {
        let start = weekStart(today: today)
        let end = LocalDay.addingDays(4, to: start)
        return "\(start.formatted(MobileLayout.dateFormat.month(.abbreviated).day())) – \(end.formatted(MobileLayout.dateFormat.month(.abbreviated).day().year()))"
    }
}
