import Foundation
import SwiftUI
import _Concurrency

// MARK: - Gamification Engine
/// Advanced gamification system with achievements, levels, streaks, and rewards
class GamificationEngine: ObservableObject {
    static let shared = GamificationEngine()
    
    @Published var currentLevel: Int = 1
    @Published var currentXP: Int = 0
    @Published var totalXP: Int = 0
    @Published var streak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var achievements: [Achievement] = []
    @Published var badges: [Badge] = []
    @Published var dailyGoals: [DailyGoal] = []
    @Published var weeklyChallenges: [WeeklyChallenge] = []
    
    // MARK: - Dependencies
    private let privacyManager = PrivacyManager.shared
    private let logger = Logger.shared
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - XP and Leveling
    private let xpPerLevel = 1000
    private let xpPerTask = 10
    private let xpPerStreak = 5
    private let xpPerAchievement = 50
    
    private init() {
        loadGamificationData()
        initializeAchievements()
        initializeBadges()
        initializeDailyGoals()
        initializeWeeklyChallenges()
    }
    
    // MARK: - XP Management
    
    func addXP(_ amount: Int, source: XPSource) {
        let startLevel = currentLevel
        currentXP += amount
        totalXP += amount
        
        // Check for level up
        let newLevel = calculateLevel(from: currentXP)
        if newLevel > startLevel {
            handleLevelUp(from: startLevel, to: newLevel)
        }
        
        logger.info("XP added: \(amount) from \(source.rawValue)", category: LogCategory.general)
        saveGamificationData()
    }
    
    private func calculateLevel(from xp: Int) -> Int {
        return max(1, (xp / xpPerLevel) + 1)
    }
    
    private func handleLevelUp(from oldLevel: Int, to newLevel: Int) {
        currentLevel = newLevel
        
        // Award level up bonus
        let levelUpBonus = (newLevel - oldLevel) * 100
        addXP(levelUpBonus, source: .levelUp)
        
        // Unlock new achievements
        checkLevelAchievements()
        
        logger.info("Level up! \(oldLevel) -> \(newLevel)", category: LogCategory.general)
    }
    
    // MARK: - Achievement System
    
    func checkAchievements(for action: AchievementAction) {
        for index in achievements.indices {
            let achievement = achievements[index]
            
            if !achievement.isUnlocked && shouldUnlockAchievement(achievement, for: action) {
                unlockAchievement(at: index)
            }
        }
    }
    
    private func shouldUnlockAchievement(_ achievement: Achievement, for action: AchievementAction) -> Bool {
        switch achievement.type {
        case .firstTask:
            return action == .taskCompleted
        case .taskCount(let count):
            return action == .taskCompleted && getCompletedTaskCount() >= count
        case .streakCount(let count):
            return action == .streakUpdated && streak >= count
        case .levelReached(let level):
            return action == .levelUp && currentLevel >= level
        case .pointsEarned(let points):
            return action == .xpEarned && totalXP >= points
        case .dailyGoal(let days):
            return action == .dailyGoalCompleted && getDailyGoalStreak() >= days
        case .weeklyChallenge:
            return action == .weeklyChallengeCompleted
        case .timeBased(let timeBased):
            return shouldUnlockTimeBasedAchievement(timeBased, for: action)
        case .voiceTasks(let count):
            return action == .taskCompleted && getVoiceTaskCount() >= count
        case .privacySettings:
            return action == .taskCompleted && isPrivacySettingsEnabled()
        }
    }
    
    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        
        // Award XP for achievement
        addXP(xpPerAchievement, source: .achievement)
        
        logger.info("Achievement unlocked: \(achievements[index].title)", category: LogCategory.general)
    }
    
    // MARK: - Badge System
    
    func awardBadge(_ badge: Badge) {
        if !badges.contains(where: { $0.id == badge.id }) {
            badges.append(badge)
            addXP(badge.xpValue, source: .badge)
            logger.info("Badge awarded: \(badge.title)", category: LogCategory.general)
            saveGamificationData()
        }
    }
    
    // MARK: - Daily Goals
    
    func completeDailyGoal(_ goal: DailyGoal) {
        if let index = dailyGoals.firstIndex(where: { $0.id == goal.id }) {
            dailyGoals[index].isCompleted = true
            dailyGoals[index].completedDate = Date()
            
            addXP(goal.xpReward, source: .dailyGoal)
            checkAchievements(for: .dailyGoalCompleted)
            
            logger.info("Daily goal completed: \(goal.title)", category: LogCategory.general)
            saveGamificationData()
        }
    }
    
    // MARK: - Weekly Challenges
    
    func completeWeeklyChallenge(_ challenge: WeeklyChallenge) {
        if let index = weeklyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            weeklyChallenges[index].isCompleted = true
            weeklyChallenges[index].completedDate = Date()
            
            addXP(challenge.xpReward, source: .weeklyChallenge)
            checkAchievements(for: .weeklyChallengeCompleted)
            
            logger.info("Weekly challenge completed: \(challenge.title)", category: LogCategory.general)
            saveGamificationData()
        }
    }
    
    // MARK: - Streak Management
    
    func updateStreak(_ newStreak: Int) {
        let oldStreak = streak
        streak = newStreak
        
        if newStreak > longestStreak {
            longestStreak = newStreak
        }
        
        // Award streak bonus XP
        if newStreak > oldStreak {
            let streakBonus = (newStreak - oldStreak) * xpPerStreak
            addXP(streakBonus, source: .streak)
        }
        
        checkAchievements(for: .streakUpdated)
        saveGamificationData()
    }
    
    // MARK: - Data Management
    
    private func loadGamificationData() {
        _Concurrency.Task.detached {
            do {
                if let data = try self.privacyManager.retrieveSecurely(GamificationData.self, forKey: "gamificationData") {
                    await MainActor.run {
                        self.currentLevel = data.currentLevel
                        self.currentXP = data.currentXP
                        self.totalXP = data.totalXP
                        self.streak = data.streak
                        self.longestStreak = data.longestStreak
                        self.achievements = data.achievements
                        self.badges = data.badges
                    }
                }
            } catch {
                self.logger.error("Failed to load gamification data", error: error, category: LogCategory.general)
            }
        }
    }
    
    private func saveGamificationData() {
        _Concurrency.Task.detached {
            do {
                let data = GamificationData(
                    currentLevel: self.currentLevel,
                    currentXP: self.currentXP,
                    totalXP: self.totalXP,
                    streak: self.streak,
                    longestStreak: self.longestStreak,
                    achievements: self.achievements,
                    badges: self.badges
                )
                try self.privacyManager.storeSecurely(data, forKey: "gamificationData")
            } catch {
                self.logger.error("Failed to save gamification data", error: error, category: LogCategory.general)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCompletedTaskCount() -> Int {
        // This would be injected from TaskManager in a real implementation
        return 0 // Placeholder
    }
    
    private func getDailyGoalStreak() -> Int {
        // Calculate consecutive days of completing daily goals
        return 0 // Placeholder
    }
    
    private func shouldUnlockTimeBasedAchievement(_ timeBased: TimeBasedAchievement, for action: AchievementAction) -> Bool {
        // Implement time-based achievement logic
        return false // Placeholder
    }
    
    private func getVoiceTaskCount() -> Int {
        // Get count of tasks created via voice
        return 0 // Placeholder
    }
    
    private func isPrivacySettingsEnabled() -> Bool {
        // Check if privacy settings are enabled
        return false // Placeholder
    }
    
    private func checkLevelAchievements() {
        checkAchievements(for: .levelUp)
    }
    
    // MARK: - Initialization Methods
    
    private func initializeAchievements() {
        if achievements.isEmpty {
            achievements = [
                Achievement(id: UUID(), title: "First Steps", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false, type: .firstTask),
                Achievement(id: UUID(), title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false, type: .taskCount(10)),
                Achievement(id: UUID(), title: "Productivity Pro", description: "Complete 50 tasks", icon: "medal.star", pointsRequired: 500, isUnlocked: false, type: .taskCount(50)),
                Achievement(id: UUID(), title: "Streak Master", description: "Maintain a 7-day streak", icon: "flame.fill", pointsRequired: 200, isUnlocked: false, type: .streakCount(7)),
                Achievement(id: UUID(), title: "Level 10", description: "Reach level 10", icon: "crown.fill", pointsRequired: 1000, isUnlocked: false, type: .levelReached(10)),
                Achievement(id: UUID(), title: "XP Collector", description: "Earn 5000 XP", icon: "trophy.fill", pointsRequired: 5000, isUnlocked: false, type: .pointsEarned(5000))
            ]
        }
    }
    
    private func initializeBadges() {
        if badges.isEmpty {
            badges = [
                Badge(id: UUID(), title: "Early Bird", description: "Complete a task before 8 AM", icon: "sunrise.fill", xpValue: 25, rarity: .common),
                Badge(id: UUID(), title: "Night Owl", description: "Complete a task after 10 PM", icon: "moon.fill", xpValue: 25, rarity: .common),
                Badge(id: UUID(), title: "Weekend Warrior", description: "Complete tasks on both weekend days", icon: "calendar.badge.clock", xpValue: 50, rarity: .uncommon),
                Badge(id: UUID(), title: "Perfect Week", description: "Complete all daily goals for a week", icon: "checkmark.seal.fill", xpValue: 100, rarity: .rare),
                Badge(id: UUID(), title: "Legendary", description: "Reach level 25", icon: "crown.fill", xpValue: 500, rarity: .legendary)
            ]
        }
    }
    
    private func initializeDailyGoals() {
        if dailyGoals.isEmpty {
            dailyGoals = [
                DailyGoal(id: UUID(), title: "Complete 3 Tasks", description: "Finish 3 tasks today", targetValue: 3, currentValue: 0, xpReward: 30, isCompleted: false),
                DailyGoal(id: UUID(), title: "Morning Productivity", description: "Complete a task before noon", targetValue: 1, currentValue: 0, xpReward: 20, isCompleted: false),
                DailyGoal(id: UUID(), title: "Consistency", description: "Maintain your streak", targetValue: 1, currentValue: 0, xpReward: 15, isCompleted: false)
            ]
        }
    }
    
    private func initializeWeeklyChallenges() {
        if weeklyChallenges.isEmpty {
            weeklyChallenges = [
                WeeklyChallenge(id: UUID(), title: "Task Marathon", description: "Complete 20 tasks this week", targetValue: 20, currentValue: 0, xpReward: 200, isCompleted: false),
                WeeklyChallenge(id: UUID(), title: "Streak Master", description: "Maintain a 5-day streak", targetValue: 7, currentValue: 0, xpReward: 150, isCompleted: false),
                WeeklyChallenge(id: UUID(), title: "Level Up", description: "Gain 2 levels this week", targetValue: 2, currentValue: 0, xpReward: 300, isCompleted: false)
            ]
        }
    }
}

// MARK: - Supporting Types

enum XPSource: String {
    case taskCompleted = "Task Completed"
    case streak = "Streak"
    case achievement = "Achievement"
    case badge = "Badge"
    case dailyGoal = "Daily Goal"
    case weeklyChallenge = "Weekly Challenge"
    case levelUp = "Level Up"
}

enum AchievementAction {
    case taskCompleted
    case streakUpdated
    case levelUp
    case xpEarned
    case dailyGoalCompleted
    case weeklyChallengeCompleted
}

// AchievementType is defined in Achievement.swift

enum BadgeRarity: Codable {
    case common
    case uncommon
    case rare
    case epic
    case legendary
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

struct Badge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let xpValue: Int
    let rarity: BadgeRarity
    var isUnlocked: Bool = false
    var unlockedDate: Date?
}

struct DailyGoal: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    var isCompleted: Bool
    var completedDate: Date?
}

struct WeeklyChallenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let targetValue: Int
    var currentValue: Int
    let xpReward: Int
    var isCompleted: Bool
    var completedDate: Date?
}

struct GamificationData: Codable {
    let currentLevel: Int
    let currentXP: Int
    let totalXP: Int
    let streak: Int
    let longestStreak: Int
    let achievements: [Achievement]
    let badges: [Badge]
}
