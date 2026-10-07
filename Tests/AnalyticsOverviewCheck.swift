import Foundation

@main
struct AnalyticsOverviewCheck {
    @MainActor
    static func main() {
        for zoneName in ["UTC", "Pacific/Honolulu", "Pacific/Kiritimati", "America/New_York", "Europe/London"] {
            let zone = TimeZone(identifier: zoneName)!
            let calendar = LocalDay.calendar(timeZone: zone)
            let date = { (year: Int, month: Int, day: Int) in
                calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
            }
            let keys = { (today: Date) in
                AnalyticsOverview.activityWeeks(today: today, timeZone: zone).map { week in
                    (LocalDay.key(for: week.monday, timeZone: zone), week.days.map { $0.map { LocalDay.key(for: $0, timeZone: zone) } })
                }
            }

            let wednesday = keys(date(2026, 10, 7))
            assert(wednesday.map(\.0) == ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28", "2026-10-05"])
            assert(wednesday[0].1 == [nil, "2026-09-08", "2026-09-09", "2026-09-10", "2026-09-11"])
            assert(wednesday[4].1 == ["2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09"])

            let monday = keys(date(2026, 10, 5))
            assert(monday.map(\.0) == ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28", "2026-10-05"])
            assert(monday[0].1.allSatisfy { $0 != nil })

            let sunday = keys(date(2026, 10, 4))
            assert(sunday.map(\.0) == ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28"])
            assert(sunday[0].1.allSatisfy { $0 != nil })

            let saturday = keys(date(2026, 10, 10))
            assert(saturday.map(\.0) == ["2026-09-07", "2026-09-14", "2026-09-21", "2026-09-28", "2026-10-05"])
            assert(saturday[0].1 == [nil, nil, nil, nil, "2026-09-11"])

            let newYear = keys(date(2027, 1, 8))
            assert(newYear.map(\.0) == ["2026-12-07", "2026-12-14", "2026-12-21", "2026-12-28", "2027-01-04"])
            assert(newYear[0].1 == [nil, nil, nil, "2026-12-10", "2026-12-11"])
            assert(newYear[3].1 == ["2026-12-28", "2026-12-29", "2026-12-30", "2026-12-31", "2027-01-01"])

            let all = AnalyticsOverview.activityWeeks(today: date(2026, 10, 7), timeZone: zone).flatMap(\.days).compactMap { $0 }
            assert(all.allSatisfy { LocalDay.isWeekday($0, timeZone: zone) })
        }

        let eastern = TimeZone(identifier: "America/New_York")!
        let before = ISO8601DateFormatter().date(from: "2026-10-05T03:59:59Z")!
        let after = ISO8601DateFormatter().date(from: "2026-10-05T04:00:00Z")!
        assert(AnalyticsOverview.activityWeeks(today: before, timeZone: eastern).map { LocalDay.key(for: $0.monday, timeZone: eastern) }.last == "2026-09-28")
        assert(AnalyticsOverview.activityWeeks(today: after, timeZone: eastern).map { LocalDay.key(for: $0.monday, timeZone: eastern) }.last == "2026-10-05")
        let dst = LocalDay.calendar(timeZone: eastern).date(from: DateComponents(year: 2026, month: 11, day: 20, hour: 12))!
        let dstWeeks = AnalyticsOverview.activityWeeks(today: dst, timeZone: eastern)
        assert(dstWeeks.map { LocalDay.key(for: $0.monday, timeZone: eastern) } == ["2026-10-19", "2026-10-26", "2026-11-02", "2026-11-09", "2026-11-16"])
        assert(dstWeeks[0].days.map { $0.map { LocalDay.key(for: $0, timeZone: eastern) } } == [nil, nil, nil, "2026-10-22", "2026-10-23"])
        print("Analytics overview checks passed: 30-day window, partial first week, weekend and Monday rollover, year boundary, DST, 5 time zones.")
    }
}
