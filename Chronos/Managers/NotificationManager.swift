import UserNotifications
import SwiftUI

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {
        requestAuthorization()
    }
    
    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                print("Notification permission granted")
                // Register for remote notifications
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    /// Schedules notifications related to the given task.
    /// - Schedules a reminder 15 minutes before the task is due.
    /// - Schedules a daily reminder at 9 PM on the due date (not just today).
    /// - Ensures no duplicate notifications exist by removing old ones first.
    func scheduleNotification(for task: Task) {
        guard task.dueDate > Date() else {
            // Do not schedule notifications for tasks with past due dates
            removeNotification(for: task)
            return
        }
        
        // Remove any existing notifications for this task to avoid duplicates
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString, "\(task.id.uuidString)_daily"])
        
        // MARK: - Schedule reminder 15 minutes before due date
        
        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "Task Reminder"
        reminderContent.body = "\(task.title) is due soon!"
        reminderContent.sound = .default
        reminderContent.badge = 1
        
        // Calculate reminder time 15 minutes before due date
        let reminderDate = task.dueDate.addingTimeInterval(-15 * 60)
        let reminderComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let reminderTrigger = UNCalendarNotificationTrigger(dateMatching: reminderComponents, repeats: false)
        
        let reminderRequest = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: reminderContent,
            trigger: reminderTrigger
        )
        
        UNUserNotificationCenter.current().add(reminderRequest) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully for task: \(task.title)")
            }
        }
        
        // MARK: - Schedule daily reminder at 9 PM on the due date
        
        if Calendar.current.isDate(task.dueDate, inSameDayAs: task.dueDate) {
            scheduleDailyReminder(for: task)
        }
    }
    
    /// Schedules a daily reminder notification at 9 PM on the task's due date.
    /// This helps prompt the user to complete today's tasks.
    private func scheduleDailyReminder(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Task Reminder"
        content.body = "Don't forget to complete \(task.title) today!"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 9 PM on the task's due date
        var components = Calendar.current.dateComponents([.year, .month, .day], from: task.dueDate)
        components.hour = 21
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(task.id.uuidString)_daily",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error.localizedDescription)")
            } else {
                print("Daily reminder scheduled successfully for task: \(task.title)")
            }
        }
    }
    
    /// Removes all notifications related to the given task,
    /// including both the main reminder and the daily reminder.
    func removeNotification(for task: Task) {
        let identifiers = [
            task.id.uuidString,
            "\(task.id.uuidString)_daily"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Removed notifications for task: \(task.title)")
    }
    
    /// Checks the current notification settings and prints the authorization status.
    func checkNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                print("Notifications are authorized")
            case .denied:
                print("Notifications are denied")
            case .notDetermined:
                print("Notification authorization not determined")
            case .provisional:
                print("Notifications are provisionally authorized")
            @unknown default:
                print("Unknown notification authorization status")
            }
        }
    }
    
    /// Schedules a notification for streak milestones (e.g., 3, 7, 14 days).
    /// - Parameter days: The number of days in the streak milestone.
    /// The notification is scheduled to be delivered at 8 AM on the milestone day.
    func scheduleStreakMilestoneNotification(days: Int) {
        guard days > 0 else { return }
        
        // Identifier for streak milestone notifications to avoid duplicates
        let identifier = "streak_milestone_\(days)"
        
        // Remove any existing streak milestone notification for this milestone
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        
        let content = UNMutableNotificationContent()
        content.title = "Congratulations!"
        content.body = "You've reached a \(days)-day streak! Keep up the great work!"
        content.sound = .default
        content.badge = 1
        
        // Schedule notification for 8 AM on the milestone day
        let milestoneDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: milestoneDate)
        components.hour = 8
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling streak milestone notification: \(error.localizedDescription)")
            } else {
                print("Streak milestone notification scheduled for \(days)-day streak")
            }
        }
    }
}

