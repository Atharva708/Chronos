import Foundation

struct Achievement:Identifiable, Codable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let pointsRequired: Int
    var isUnlocked: Bool

    static let achievements = [
        Achievement(title: "Getting Started", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false),
        Achievement(title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false),
        Achievement(title: "Productivity Pro", description: "Reach 1000 points", icon: "medal.star", pointsRequired: 1000, isUnlocked: false),
        Achievement(title: "Productivity King", description: "Reach 10000 points", icon: "crown.fill", pointsRequired: 10000, isUnlocked: false),
        Achievement(title: "Productivity Legend", description: "Reach 100000 points", icon: "trophy.fill", pointsRequired: 100000, isUnlocked: false)
    ]
}
