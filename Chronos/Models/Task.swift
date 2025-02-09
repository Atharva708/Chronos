import Foundation

struct Task: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var dueDate: Date
    var isCompleted: Bool
    var completedDate: Date?
    var priority: TaskPriority = .medium
    
    static let COMPLETION_POINTS = 10
} 