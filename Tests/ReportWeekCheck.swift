import Foundation

@main
struct ReportWeekCheck {
    @MainActor
    static func main() {
        let now = ISO8601DateFormatter().date(from: "2026-09-21T01:00:00Z")!
        for zoneName in ["UTC", "Pacific/Honolulu", "Pacific/Kiritimati", "America/New_York", "Europe/London"] {
            let zone = TimeZone(identifier: zoneName)!
            let historical = QuestionPerformanceView.startOfWeek(selectedWeek: "2026-09-14", today: now, timeZone: zone)
            assert(LocalDay.key(for: historical, timeZone: zone) == "2026-09-14")
            assert(LocalDay.calendar(timeZone: zone).component(.weekday, from: historical) == 2)
            for offset in 0..<5 {
                let day = LocalDay.addingDays(offset, to: historical, timeZone: zone)
                assert(LocalDay.key(for: day, timeZone: zone) == "2026-09-\(14 + offset)")
                assert(LocalDay.isWeekday(day, timeZone: zone))
            }
            let current = QuestionPerformanceView.startOfWeek(selectedWeek: nil, today: now, timeZone: zone)
            let expected = ["Pacific/Honolulu", "America/New_York"].contains(zoneName) ? "2026-09-14" : "2026-09-21"
            assert(LocalDay.key(for: current, timeZone: zone) == expected)

            let september28 = LocalDay.calendar(timeZone: zone).date(from: DateComponents(year: 2026, month: 9, day: 28, hour: 12))!
            let activity = QuestionPerformanceView.activityDates(today: september28, timeZone: zone)
            assert(activity.count == 20)
            assert(LocalDay.key(for: activity[0], timeZone: zone) == "2026-09-07")
            assert(LocalDay.key(for: activity[15], timeZone: zone) == "2026-09-28")
            assert(LocalDay.key(for: activity[19], timeZone: zone) == "2026-10-02")
            assert(activity.allSatisfy { LocalDay.isWeekday($0, timeZone: zone) })
        }
        let eastern = TimeZone(identifier: "America/New_York")!
        let before = ISO8601DateFormatter().date(from: "2026-09-21T03:59:59Z")!
        let after = ISO8601DateFormatter().date(from: "2026-09-21T04:00:00Z")!
        assert(LocalDay.key(for: QuestionPerformanceView.startOfWeek(selectedWeek: nil, today: before, timeZone: eastern), timeZone: eastern) == "2026-09-14")
        assert(LocalDay.key(for: QuestionPerformanceView.startOfWeek(selectedWeek: nil, today: after, timeZone: eastern), timeZone: eastern) == "2026-09-21")
        let gregorian = Date.FormatStyle(locale: Locale(identifier: "en_US@calendar=buddhist"), calendar: LocalDay.calendar(timeZone: eastern), timeZone: eastern).year()
        assert(after.formatted(gregorian) == "2026")
        let sunday = LocalDay.calendar(timeZone: eastern).date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 12))!
        let nextMonday = LocalDay.addingDays(1, to: sunday, timeZone: eastern)
        assert(LocalDay.key(for: QuestionPerformanceView.activityDates(today: sunday, timeZone: eastern)[0], timeZone: eastern) == "2026-09-07")
        assert(LocalDay.key(for: QuestionPerformanceView.activityDates(today: nextMonday, timeZone: eastern)[0], timeZone: eastern) == "2026-09-14")
        let newYear = LocalDay.calendar(timeZone: eastern).date(from: DateComponents(year: 2027, month: 1, day: 1, hour: 12))!
        let yearEndActivity = QuestionPerformanceView.activityDates(today: newYear, timeZone: eastern)
        assert(LocalDay.key(for: yearEndActivity[0], timeZone: eastern) == "2026-12-07")
        assert(LocalDay.key(for: yearEndActivity[19], timeZone: eastern) == "2027-01-01")
        print("Report checks passed: weekly navigation, four-week activity, 5 time zones, midnight rollover, year boundary.")
    }
}
