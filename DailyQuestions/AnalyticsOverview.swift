import SwiftUI

struct ActivityWeek {
    let monday: Date
    let days: [Date?]
}

struct AnalyticsOverview: View {
    let store: DailyStore
    let onSelect: (DailyQuestion) -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(today: context.date)

                    let questions = store.questions.filter { $0.archivedDay == nil }
                    if questions.isEmpty {
                        Text("No active questions")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 236), spacing: 16)], alignment: .leading, spacing: 16) {
                            ForEach(questions) { question in
                                card(question, today: context.date)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 56)
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
    }

    private func header(today: Date) -> some View {
        let start = LocalDay.addingDays(-29, to: today)
        let range = Text("Last 30 days · \(start.formatted(dateFormat.month(.abbreviated).day())) – \(today.formatted(dateFormat.month(.abbreviated).day().year()))")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)

        return VStack(alignment: .leading, spacing: 8) {
            Text("Analytics")
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) {
                    range
                    Spacer(minLength: 0)
                    legend
                }
                VStack(alignment: .leading, spacing: 8) {
                    range
                    legend
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem("Yes", fill: Palette.ink, stroke: Palette.ink)
            legendItem("No", fill: Palette.selection, stroke: Palette.border)
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
    }

    private func legendItem(_ title: String, fill: Color, stroke: Color) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(fill)
                .frame(width: 14, height: 14)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(stroke, lineWidth: 1)
                }
                .accessibilityHidden(true)
            Text(title)
        }
    }

    private func card(_ question: DailyQuestion, today: Date) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Button { onSelect(question) } label: {
                Text(question.text)
                    .font(.system(size: 16, weight: .semibold))
                    .lineSpacing(2)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 42, maxHeight: 42, alignment: .topLeading)
            }
            .buttonStyle(.plain)
            .help(question.text)
            .accessibilityHint("Open analytics")

            activityGrid(question, today: today)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.border, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { onSelect(question) }
    }

    private func activityGrid(_ question: DailyQuestion, today: Date) -> some View {
        let todayKey = LocalDay.key(for: today)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Color.clear.frame(width: 40, height: 1)
                ForEach(["Mon", "Tue", "Wed", "Thu", "Fri"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 32)
                }
            }
            .accessibilityHidden(true)

            ForEach(Self.activityWeeks(today: today), id: \.monday) { week in
                HStack(spacing: 8) {
                    Text(week.monday.formatted(dateFormat.month(.abbreviated).day()))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .frame(width: 40, alignment: .trailing)
                        .accessibilityHidden(true)
                    ForEach(0..<5, id: \.self) { weekday in
                        if let date = week.days[weekday] {
                            cell(question, date: date, isToday: LocalDay.key(for: date) == todayKey)
                        } else {
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: 32)
                                .accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }

    private func cell(_ question: DailyQuestion, date: Date, isToday: Bool) -> some View {
        let yes = store.savedAnswer(for: question, day: LocalDay.key(for: date))?.value == true
        let status = yes ? "Yes" : "No"
        let label = date.formatted(dateFormat.weekday(.wide).month(.wide).day().year())

        return RoundedRectangle(cornerRadius: 6)
            .fill(yes ? Palette.ink : Palette.selection)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(yes ? Palette.ink : Palette.border, lineWidth: 1)
            }
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 9.5)
                        .strokeBorder(.secondary, lineWidth: 1.5)
                        .padding(-3.5)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 32)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(status)
            .help("\(label): \(status)")
            .focusable()
    }

    static func activityWeeks(today: Date, timeZone: TimeZone = .current) -> [ActivityWeek] {
        let start = LocalDay.addingDays(-29, to: today, timeZone: timeZone)
        let startKey = LocalDay.key(for: start, timeZone: timeZone)
        let todayKey = LocalDay.key(for: today, timeZone: timeZone)
        let firstMonday = LocalDay.monday(of: start, timeZone: timeZone)
        return (0..<6).map { week in
            let monday = LocalDay.addingDays(week * 7, to: firstMonday, timeZone: timeZone)
            return ActivityWeek(monday: monday, days: (0..<5).map { weekday in
                let date = LocalDay.addingDays(weekday, to: monday, timeZone: timeZone)
                return LocalDay.key(for: date, timeZone: timeZone) < startKey ? nil : date
            })
        }
        .filter { week in
            LocalDay.key(for: week.monday, timeZone: timeZone) <= todayKey && week.days.contains { $0 != nil }
        }
    }

    private var dateFormat: Date.FormatStyle {
        Date.FormatStyle(calendar: LocalDay.calendar(), timeZone: .current)
    }
}
