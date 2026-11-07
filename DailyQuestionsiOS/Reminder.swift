import Foundation
import UserNotifications

enum Reminder {
    private static let weekdays = 2...6

    static func update(enabled: Bool, minuteOfDay: Int) async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: weekdays.map(identifier))
        guard enabled else { return true }
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { return false }
        let content = UNMutableNotificationContent()
        content.title = "Daily Questions"
        content.body = "Today's questions are ready to answer."
        content.sound = .default
        for weekday in weekdays {
            var components = DateComponents()
            components.weekday = weekday
            components.hour = minuteOfDay / 60
            components.minute = minuteOfDay % 60
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            try await center.add(UNNotificationRequest(identifier: identifier(weekday), content: content, trigger: trigger))
        }
        return true
    }

    private static func identifier(_ weekday: Int) -> String {
        "weekday-reminder-\(weekday)"
    }
}
