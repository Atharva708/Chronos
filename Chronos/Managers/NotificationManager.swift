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
    
    func scheduleNotification(for task: Task) {
        // Remove any existing notifications for this task
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = "\(task.title) is due soon!"
        content.sound = .default
        content.badge = 1
        
        // Schedule notification for 15 minutes before due time
        let reminderDate = task.dueDate.addingTimeInterval(-15 * 60)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create and add the notification request
        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully for task: \(task.title)")
            }
        }
        
        // Schedule a daily reminder for today's tasks
        if Calendar.current.isDateInToday(task.dueDate) {
            scheduleDailyReminder(for: task)
        }
    }
    
    private func scheduleDailyReminder(for task: Task) {
        let content = UNMutableNotificationContent()
        content.title = "Daily Task Reminder"
        content.body = "Don't forget to complete \(task.title) today!"
        content.sound = .default
        content.badge = 1
        
        // Schedule for 9 PM
        var components = DateComponents()
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
            }
        }
    }
    
    func removeNotification(for task: Task) {
        let identifiers = [
            task.id.uuidString,
            "\(task.id.uuidString)_daily"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
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
} 