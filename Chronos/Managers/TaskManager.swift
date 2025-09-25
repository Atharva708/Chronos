import Foundation
import Combine
import _Concurrency

// MARK: - Enhanced Task Manager
/// Production-ready task manager with privacy protection, error handling, and comprehensive logging
class TaskManager: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            _Concurrency.Task.detached {
                await self.saveTasksSecurely()
            }
        }
    }
    @Published var points: Int = 0 {
        didSet {
            _Concurrency.Task.detached {
                await self.savePointsSecurely()
            }
            // Update level when points change
            level = points / 100
        }
    }
    @Published var achievements: [Achievement] = [
        Achievement(id: UUID(), title: "Getting Started", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false, type: .firstTask),
        Achievement(id: UUID(), title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false, type: .taskCount(10)),
        Achievement(id: UUID(), title: "Productivity Pro", description: "Reach 1000 points", icon: "medal.star", pointsRequired: 1000, isUnlocked: false, type: .pointsEarned(1000)),
        Achievement(id: UUID(), title: "Productivity King", description: "Reach 10000 points", icon: "crown.fill", pointsRequired: 10000, isUnlocked: false, type: .pointsEarned(10000)),
        Achievement(id: UUID(), title: "Productivity Legend", description: "Reach 100000 points", icon: "trophy.fill", pointsRequired: 100000, isUnlocked: false, type: .pointsEarned(100000)),
        
        // New streak and task completion achievements
        Achievement(id: UUID(), title: "3-Day Streak", description: "Complete tasks 3 days in a row", icon: "flame.fill", pointsRequired: 0, isUnlocked: false, type: .streakCount(3)),
        Achievement(id: UUID(), title: "7-Day Streak", description: "Complete tasks 7 days in a row", icon: "flame.circle.fill", pointsRequired: 0, isUnlocked: false, type: .streakCount(7)),
        Achievement(id: UUID(), title: "14-Day Streak", description: "Complete tasks 14 days in a row", icon: "flame.fill", pointsRequired: 0, isUnlocked: false, type: .streakCount(14)),
        Achievement(id: UUID(), title: "30-Day Streak", description: "Complete tasks 30 days in a row", icon: "flame.circle.fill", pointsRequired: 0, isUnlocked: false, type: .streakCount(30)),
        Achievement(id: UUID(), title: "50 Tasks Completed", description: "Complete 50 tasks total", icon: "checkmark.seal.fill", pointsRequired: 0, isUnlocked: false, type: .taskCount(50))
    ] {
        didSet {
            saveAchievements()
        }
    }
    
    // New published properties for streak tracking and level
    @Published var currentStreak: Int = 0 {
        didSet {
            saveStreakData()
        }
    }
    @Published var longestStreak: Int = 0 {
        didSet {
            saveStreakData()
        }
    }
    @Published var lastCompletionDate: Date? = nil {
        didSet {
            saveStreakData()
        }
    }
    
    @Published var level: Int = 0
    
    // MARK: - Dependencies
    private let privacyManager = PrivacyManager.shared
    private let logger = Logger.shared
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Storage Keys
    private let tasksKey = "savedTasks"
    private let pointsKey = "savedPoints"
    private let achievementsKey = "savedAchievements"
    private let currentStreakKey = "savedCurrentStreak"
    private let longestStreakKey = "savedLongestStreak"
    private let lastCompletionDateKey = "savedLastCompletionDate"
    
    // Tracks total completed tasks for achievements
    private var totalCompletedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    init() {
        _Concurrency.Task.detached {
            await self.loadAllData()
        }
    }
    
    // MARK: - Async Data Loading
    
    @MainActor
    private func loadAllData() async {
        do {
            await loadTasksSecurely()
            await loadPointsSecurely()
            await loadAchievementsSecurely()
            await loadStreakDataSecurely()
            level = points / 100
            logger.info("All task data loaded successfully", category: LogCategory.taskManager)
        } catch {
            logger.error("Failed to load task data", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.loadFailed, context: "loadAllData")
        }
    }
    
    // MARK: - Task Operations
    
    func addTask(_ task: Task) {
        logger.logTaskOperation("add_task", taskId: task.id.uuidString)
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        logger.logTaskOperation("delete_task", taskId: task.id.uuidString)
        tasks.removeAll { $0.id == task.id }
        // Recalculate streak if needed (optional)
        recalculateStreakIfNeeded()
    }
    
    // MARK: - Voice Task Creation
    
    func createTaskFromVoice(_ processedTask: ProcessedTask) {
        let task = Task(
            title: processedTask.title,
            description: processedTask.description,
            dueDate: processedTask.dueDate ?? Date(),
            isCompleted: false,
            priority: processedTask.priority
        )
        
        logger.logTaskOperation("create_from_voice", taskId: task.id.uuidString)
        addTask(task)
    }
    
    func toggleTaskCompletion(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        let wasCompleted = tasks[index].isCompleted
        tasks[index].isCompleted.toggle()
        tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil
        
        if tasks[index].isCompleted {
            // Add base completion points
            points += Task.COMPLETION_POINTS
            
            // Handle streak logic only if task just completed
            handleStreakOnCompletion()
            
            // Check total completed tasks achievements
            checkTotalTasksAchievements()
        } else {
            // Removing completion points (user unchecked task)
            points = max(points - Task.COMPLETION_POINTS, 0)
            
            // Optionally recalculate streak on uncompletion
            recalculateStreakIfNeeded()
        }
        
        // Update achievements based on points
        updatePointsBasedAchievements()
        
        // Save tasks manually because we modified them directly
        saveTasks()
    }
    
    // MARK: - Streak and Achievement Handling
    
    private func handleStreakOnCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastDate = lastCompletionDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let daysBetween = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysBetween == 1 {
                // Consecutive day: increment streak
                currentStreak += 1
            } else if daysBetween > 1 {
                // Non-consecutive day: reset streak to 1
                currentStreak = 1
            } else if daysBetween == 0 {
                // Same day completion - do not increment streak multiple times
                // Do nothing with streak
            } else {
                // Future date or unexpected case: reset streak to 1
                currentStreak = 1
            }
        } else {
            // No last completion date means first completed task ever
            currentStreak = 1
        }
        
        // Update longest streak if current goes beyond it
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
        
        // Update last completion date to today
        lastCompletionDate = Date()
        
        // Award bonus points and unlock achievements for streak milestones
        checkStreakMilestones()
    }
    
    private func recalculateStreakIfNeeded() {
        // Recalculate current streak by scanning completed tasks dates in descending order
        // This handles uncompletion or deletion cases
        
        // Get all unique days where tasks were completed
        let completedDates = tasks.compactMap { $0.completedDate }.map { Calendar.current.startOfDay(for: $0) }
        let uniqueDays = Array(Set(completedDates)).sorted(by: >) // sorted descending
        
        guard !uniqueDays.isEmpty else {
            // No completed tasks, reset streak data
            currentStreak = 0
            lastCompletionDate = nil
            return
        }
        
        var recalculatedStreak = 1
        var lastDay = uniqueDays[0]
        
        for i in 1..<uniqueDays.count {
            let previousDay = uniqueDays[i]
            let diff = Calendar.current.dateComponents([.day], from: previousDay, to: lastDay).day ?? 0
            if diff == 1 {
                recalculatedStreak += 1
                lastDay = previousDay
            } else {
                break
            }
        }
        
        currentStreak = recalculatedStreak
        longestStreak = max(longestStreak, currentStreak)
        lastCompletionDate = uniqueDays[0]
    }
    
    private func checkStreakMilestones() {
        // Milestones to check and their bonus points
        // 3-day, 7-day, 14-day, 30-day streaks
        let milestones: [Int: Int] = [
            3: 50,
            7: 150,
            14: 400,
            30: 1000
        ]
        
        // For each milestone, if currentStreak reached and corresponding achievement not unlocked, award bonus and unlock achievement
        for (days, bonus) in milestones {
            if currentStreak == days {
                if let index = achievements.firstIndex(where: { $0.title.contains("\(days)-Day Streak") }) {
                    if !achievements[index].isUnlocked {
                        // Award bonus points for streak milestone
                        points += bonus
                        // Unlock streak milestone achievement
                        let updatedAchievement = Achievement(
                            id: achievements[index].id,
                            title: achievements[index].title,
                            description: achievements[index].description,
                            icon: achievements[index].icon,
                            pointsRequired: achievements[index].pointsRequired,
                            isUnlocked: true,
                            type: achievements[index].type,
                            rarity: achievements[index].rarity
                        )
                        achievements[index] = updatedAchievement
                    }
                }
            }
        }
    }
    
    private func checkTotalTasksAchievements() {
        // Unlock "50 Tasks Completed" achievement if conditions met
        if totalCompletedTasks >= 50 {
            if let index = achievements.firstIndex(where: { $0.title == "50 Tasks Completed" }) {
                if !achievements[index].isUnlocked {
                    let updatedAchievement = Achievement(
                        id: achievements[index].id,
                        title: achievements[index].title,
                        description: achievements[index].description,
                        icon: achievements[index].icon,
                        pointsRequired: achievements[index].pointsRequired,
                        isUnlocked: true,
                        type: achievements[index].type,
                        rarity: achievements[index].rarity
                    )
                    achievements[index] = updatedAchievement
                    // Award bonus points for this achievement
                    points += 200
                }
            }
        }
        
        // Also unlock "Getting Started" and "Task Master" based on completed tasks counts
        if totalCompletedTasks >= 1 {
            if let index = achievements.firstIndex(where: { $0.title == "Getting Started" }) {
                if !achievements[index].isUnlocked {
                    let updatedAchievement = Achievement(
                        id: achievements[index].id,
                        title: achievements[index].title,
                        description: achievements[index].description,
                        icon: achievements[index].icon,
                        pointsRequired: achievements[index].pointsRequired,
                        isUnlocked: true,
                        type: achievements[index].type,
                        rarity: achievements[index].rarity
                    )
                    achievements[index] = updatedAchievement
                    points += 10
                }
            }
        }
        if totalCompletedTasks >= 10 {
            if let index = achievements.firstIndex(where: { $0.title == "Task Master" }) {
                if !achievements[index].isUnlocked {
                    let updatedAchievement = Achievement(
                        id: achievements[index].id,
                        title: achievements[index].title,
                        description: achievements[index].description,
                        icon: achievements[index].icon,
                        pointsRequired: achievements[index].pointsRequired,
                        isUnlocked: true,
                        type: achievements[index].type,
                        rarity: achievements[index].rarity
                    )
                    achievements[index] = updatedAchievement
                    points += 90 // To total 100 points as in pointsRequired
                }
            }
        }
    }
    
    private func updatePointsBasedAchievements() {
        // Unlock achievements based on points thresholds
        for index in achievements.indices {
            // For streak and task count achievements with pointsRequired == 0, skip this update
            if achievements[index].pointsRequired > 0 && !achievements[index].isUnlocked {
                if points >= achievements[index].pointsRequired {
                    let updatedAchievement = Achievement(
                        id: achievements[index].id,
                        title: achievements[index].title,
                        description: achievements[index].description,
                        icon: achievements[index].icon,
                        pointsRequired: achievements[index].pointsRequired,
                        isUnlocked: true,
                        type: achievements[index].type,
                        rarity: achievements[index].rarity
                    )
                    achievements[index] = updatedAchievement
                }
            }
        }
    }
    
    // MARK: - Secure Data Persistence
    
    private func saveTasksSecurely() async {
        do {
            try privacyManager.storeSecurely(tasks, forKey: tasksKey)
            logger.info("Tasks saved securely", category: LogCategory.taskManager)
        } catch {
            logger.error("Failed to save tasks securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.saveFailed, context: "saveTasksSecurely")
        }
    }
    
    private func loadTasksSecurely() async {
        do {
            if let loadedTasks = try privacyManager.retrieveSecurely([Task].self, forKey: tasksKey) {
                await MainActor.run {
                    self.tasks = loadedTasks
                }
                logger.info("Tasks loaded securely", category: LogCategory.taskManager)
            }
        } catch {
            logger.error("Failed to load tasks securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.loadFailed, context: "loadTasksSecurely")
        }
    }
    
    private func savePointsSecurely() async {
        do {
            try privacyManager.storeSecurely(points, forKey: pointsKey)
            logger.info("Points saved securely", category: LogCategory.taskManager)
        } catch {
            logger.error("Failed to save points securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.saveFailed, context: "savePointsSecurely")
        }
    }
    
    private func loadPointsSecurely() async {
        do {
            if let loadedPoints = try privacyManager.retrieveSecurely(Int.self, forKey: pointsKey) {
                await MainActor.run {
                    self.points = loadedPoints
                }
                logger.info("Points loaded securely", category: LogCategory.taskManager)
            }
        } catch {
            logger.error("Failed to load points securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.loadFailed, context: "loadPointsSecurely")
        }
    }
    
    private func saveAchievementsSecurely() async {
        do {
            try privacyManager.storeSecurely(achievements, forKey: achievementsKey)
            logger.info("Achievements saved securely", category: LogCategory.taskManager)
        } catch {
            logger.error("Failed to save achievements securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.saveFailed, context: "saveAchievementsSecurely")
        }
    }
    
    private func loadAchievementsSecurely() async {
        do {
            if let loadedAchievements = try privacyManager.retrieveSecurely([Achievement].self, forKey: achievementsKey) {
                await MainActor.run {
                    self.achievements = loadedAchievements
                }
                logger.info("Achievements loaded securely", category: LogCategory.taskManager)
            }
        } catch {
            logger.error("Failed to load achievements securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.loadFailed, context: "loadAchievementsSecurely")
        }
    }
    
    private func saveStreakDataSecurely() async {
        do {
            let streakData = StreakData(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastCompletionDate: lastCompletionDate
            )
            try privacyManager.storeSecurely(streakData, forKey: "streakData")
            logger.info("Streak data saved securely", category: LogCategory.taskManager)
        } catch {
            logger.error("Failed to save streak data securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.saveFailed, context: "saveStreakDataSecurely")
        }
    }
    
    private func loadStreakDataSecurely() async {
        do {
            if let streakData = try privacyManager.retrieveSecurely(StreakData.self, forKey: "streakData") {
                await MainActor.run {
                    self.currentStreak = streakData.currentStreak
                    self.longestStreak = streakData.longestStreak
                    self.lastCompletionDate = streakData.lastCompletionDate
                }
                logger.info("Streak data loaded securely", category: LogCategory.taskManager)
            }
        } catch {
            logger.error("Failed to load streak data securely", error: error, category: LogCategory.taskManager)
            errorHandler.handleTaskError(.loadFailed, context: "loadStreakDataSecurely")
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    
    private func saveTasks() {
        _Concurrency.Task.detached {
            await self.saveTasksSecurely()
        }
    }
    
    private func loadTasks() {
        _Concurrency.Task.detached {
            await self.loadTasksSecurely()
        }
    }
    
    private func savePoints() {
        _Concurrency.Task.detached {
            await self.savePointsSecurely()
        }
    }
    
    private func loadPoints() {
        _Concurrency.Task.detached {
            await self.loadPointsSecurely()
        }
    }
    
    private func saveAchievements() {
        _Concurrency.Task.detached {
            await self.saveAchievementsSecurely()
        }
    }
    
    private func loadAchievements() {
        _Concurrency.Task.detached {
            await self.loadAchievementsSecurely()
        }
    }
    
    private func saveStreakData() {
        _Concurrency.Task.detached {
            await self.saveStreakDataSecurely()
        }
    }
    
    private func loadStreakData() {
        _Concurrency.Task.detached {
            await self.loadStreakDataSecurely()
        }
    }
}

// MARK: - Supporting Types

struct StreakData: Codable {
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletionDate: Date?
}

