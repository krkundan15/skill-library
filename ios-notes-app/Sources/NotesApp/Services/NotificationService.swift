import Foundation
import UserNotifications
import NotesShared

/// Schedules local notifications for action items that have a due date.
public final class NotificationService {

    public static let shared = NotificationService()
    private init() {}

    /// Requests notification authorisation and schedules a reminder for the action item.
    public func schedule(for item: ActionItem) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted, let due = item.dueDate else { return }
            self.scheduleNotification(title: item.title, id: item.id.uuidString, at: due)
        }
    }

    public func cancel(for itemID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [itemID.uuidString]
        )
    }

    // MARK: - Private

    private func scheduleNotification(title: String, id: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Action Item"
        content.body = title
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[NotificationService] Failed to schedule: \(error.localizedDescription)")
            }
        }
    }
}
