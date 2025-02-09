import Foundation

struct Achievement: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var pointsRequired: Int
    var icon: String // SF Symbol name
    var isUnlocked: Bool
    
    static let achievements = [
        Achievement(title: "Getting Started", description: "Complete your first task", pointsRequired: 10, icon: "star.fill", isUnlocked: false),
        Achievement(title: "Task Master", description: "Complete 10 tasks", pointsRequired: 100, icon: "star.circle.fill", isUnlocked: false),
        Achievement(title: "Productivity Pro", description: "Reach 1000 points", pointsRequired: 1000, icon: "crown.fill", isUnlocked: false),
        Achievement(title: "Legend", description: "Reach 10000 points", pointsRequired: 10000, icon: "trophy.fill", isUnlocked: false)
    ]
} 