import Foundation
import SwiftUI

// MARK: - Enhanced Achievement Model
struct Achievement: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let pointsRequired: Int
    var isUnlocked: Bool
    var unlockedDate: Date?
    let type: AchievementType
    let rarity: AchievementRarity
    
    init(id: UUID, title: String, description: String, icon: String, pointsRequired: Int, isUnlocked: Bool, type: AchievementType, rarity: AchievementRarity = .common) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.pointsRequired = pointsRequired
        self.isUnlocked = isUnlocked
        self.type = type
        self.rarity = rarity
    }
    
    // MARK: - Static Achievement Collections
    
    static let basicAchievements = [
        Achievement(id: UUID(), title: "Getting Started", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false, type: .firstTask),
        Achievement(id: UUID(), title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false, type: .taskCount(10)),
        Achievement(id: UUID(), title: "Productivity Pro", description: "Complete 50 tasks", icon: "medal.star", pointsRequired: 500, isUnlocked: false, type: .taskCount(50)),
        Achievement(id: UUID(), title: "Productivity King", description: "Complete 100 tasks", icon: "crown.fill", pointsRequired: 1000, isUnlocked: false, type: .taskCount(100)),
        Achievement(id: UUID(), title: "Productivity Legend", description: "Complete 500 tasks", icon: "trophy.fill", pointsRequired: 5000, isUnlocked: false, type: .taskCount(500), rarity: .legendary)
    ]
    
    static let streakAchievements = [
        Achievement(id: UUID(), title: "3-Day Streak", description: "Complete tasks 3 days in a row", icon: "flame.fill", pointsRequired: 50, isUnlocked: false, type: .streakCount(3)),
        Achievement(id: UUID(), title: "7-Day Streak", description: "Complete tasks 7 days in a row", icon: "flame.circle.fill", pointsRequired: 100, isUnlocked: false, type: .streakCount(7)),
        Achievement(id: UUID(), title: "14-Day Streak", description: "Complete tasks 14 days in a row", icon: "flame.fill", pointsRequired: 200, isUnlocked: false, type: .streakCount(14)),
        Achievement(id: UUID(), title: "30-Day Streak", description: "Complete tasks 30 days in a row", icon: "flame.circle.fill", pointsRequired: 500, isUnlocked: false, type: .streakCount(30), rarity: .epic)
    ]
    
    static let levelAchievements = [
        Achievement(id: UUID(), title: "Level 5", description: "Reach level 5", icon: "5.circle.fill", pointsRequired: 250, isUnlocked: false, type: .levelReached(5)),
        Achievement(id: UUID(), title: "Level 10", description: "Reach level 10", icon: "10.circle.fill", pointsRequired: 500, isUnlocked: false, type: .levelReached(10)),
        Achievement(id: UUID(), title: "Level 25", description: "Reach level 25", icon: "25.circle.fill", pointsRequired: 1000, isUnlocked: false, type: .levelReached(25), rarity: .rare),
        Achievement(id: UUID(), title: "Level 50", description: "Reach level 50", icon: "50.circle.fill", pointsRequired: 2500, isUnlocked: false, type: .levelReached(50), rarity: .epic)
    ]
    
    static let specialAchievements = [
        Achievement(id: UUID(), title: "Early Bird", description: "Complete a task before 8 AM", icon: "sunrise.fill", pointsRequired: 25, isUnlocked: false, type: .timeBased(.earlyMorning), rarity: .uncommon),
        Achievement(id: UUID(), title: "Night Owl", description: "Complete a task after 10 PM", icon: "moon.fill", pointsRequired: 25, isUnlocked: false, type: .timeBased(.lateNight), rarity: .uncommon),
        Achievement(id: UUID(), title: "Weekend Warrior", description: "Complete tasks on both weekend days", icon: "calendar.badge.clock", pointsRequired: 50, isUnlocked: false, type: .timeBased(.weekend), rarity: .rare),
        Achievement(id: UUID(), title: "Voice Master", description: "Create 10 tasks using voice input", icon: "mic.fill", pointsRequired: 100, isUnlocked: false, type: .voiceTasks(10), rarity: .uncommon),
        Achievement(id: UUID(), title: "Privacy Champion", description: "Enable maximum privacy settings", icon: "lock.shield.fill", pointsRequired: 75, isUnlocked: false, type: .privacySettings, rarity: .rare)
    ]
    
    static var allAchievements: [Achievement] {
        return basicAchievements + streakAchievements + levelAchievements + specialAchievements
    }
}

// MARK: - Achievement Types

enum AchievementType: Codable, Equatable {
    case firstTask
    case taskCount(Int)
    case streakCount(Int)
    case levelReached(Int)
    case pointsEarned(Int)
    case dailyGoal(Int)
    case weeklyChallenge
    case timeBased(TimeBasedAchievement)
    case voiceTasks(Int)
    case privacySettings
}

enum TimeBasedAchievement: String, Codable, CaseIterable {
    case earlyMorning = "Early Morning"
    case lateNight = "Late Night"
    case weekend = "Weekend"
    case weekday = "Weekday"
}

enum AchievementRarity: String, Codable, CaseIterable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .common: return "circle.fill"
        case .uncommon: return "circle.circle.fill"
        case .rare: return "diamond.fill"
        case .epic: return "star.fill"
        case .legendary: return "crown.fill"
        }
    }
}
