import Foundation
import EventKit

/// Utility to handle optional calendar sync for tasks
class CalendarSyncManager: ObservableObject {
    static let shared = CalendarSyncManager()
    private let eventStore = EKEventStore()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorization()
    }
    
    /// Check EventKit authorization status
    func checkAuthorization() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            eventStore.requestAccess(to: .event) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
            }
        default:
            isAuthorized = false
        }
    }
    
    /// Add a task as a calendar event (optional sync)
    func addTaskToCalendar(task: Task, completion: @escaping (Bool, Error?) -> Void) {
        checkAuthorization()
        guard isAuthorized else {
            completion(false, nil)
            return
        }
        let event = EKEvent(eventStore: eventStore)
        event.title = task.title
        event.notes = task.description
        event.startDate = task.dueDate
        event.endDate = task.dueDate.addingTimeInterval(60 * 60) // Default 1 hr event
        event.calendar = eventStore.defaultCalendarForNewEvents
        do {
            try eventStore.save(event, span: .thisEvent)
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }
}

// Add a brief note: Use CalendarSyncManager.shared.addTaskToCalendar(task:completion:) in your AddTaskView or TaskDetailView when the user requests calendar sync.
