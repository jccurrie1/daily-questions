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
        }
        let eastern = TimeZone(identifier: "America/New_York")!
        let before = ISO8601DateFormatter().date(from: "2026-09-21T03:59:59Z")!
        let after = ISO8601DateFormatter().date(from: "2026-09-21T04:00:00Z")!
        assert(LocalDay.key(for: QuestionPerformanceView.startOfWeek(selectedWeek: nil, today: before, timeZone: eastern), timeZone: eastern) == "2026-09-14")
        assert(LocalDay.key(for: QuestionPerformanceView.startOfWeek(selectedWeek: nil, today: after, timeZone: eastern), timeZone: eastern) == "2026-09-21")
        let gregorian = Date.FormatStyle(locale: Locale(identifier: "en_US@calendar=buddhist"), calendar: LocalDay.calendar(timeZone: eastern), timeZone: eastern).year()
        assert(after.formatted(gregorian) == "2026")
        print("Report week checks passed: 5 time zones, 25 weekday dates, midnight rollover, Gregorian formatting.")
    }
}
