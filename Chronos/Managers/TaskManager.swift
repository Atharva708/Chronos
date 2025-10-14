import Foundation
import Combine

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = [] {
        didSet {
            saveTasks()
        }
    }
    @Published var points: Int = 0 {
        didSet {
            savePoints()
            // Update level when points change
            level = points / 100
        }
    }
    @Published var achievements: [Achievement] = [
        Achievement(id: UUID(), title: "Getting Started", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false),
        Achievement(id: UUID(), title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false),
        Achievement(id: UUID(), title: "Productivity Pro", description: "Reach 1000 points", icon: "medal.star", pointsRequired: 1000, isUnlocked: false),
        Achievement(id: UUID(), title: "Productivity King", description: "Reach 10000 points", icon: "crown.fill", pointsRequired: 10000, isUnlocked: false),
        Achievement(id: UUID(), title: "Productivity Legend", description: "Reach 100000 points", icon: "trophy.fill", pointsRequired: 100000, isUnlocked: false),
        
        // New streak and task completion achievements
        Achievement(id: UUID(), title: "3-Day Streak", description: "Complete tasks 3 days in a row", icon: "flame.fill", pointsRequired: 0, isUnlocked: false),
        Achievement(id: UUID(), title: "7-Day Streak", description: "Complete tasks 7 days in a row", icon: "flame.circle.fill", pointsRequired: 0, isUnlocked: false),
        Achievement(id: UUID(), title: "14-Day Streak", description: "Complete tasks 14 days in a row", icon: "flame.fill", pointsRequired: 0, isUnlocked: false),
        Achievement(id: UUID(), title: "30-Day Streak", description: "Complete tasks 30 days in a row", icon: "flame.circle.fill", pointsRequired: 0, isUnlocked: false),
        Achievement(id: UUID(), title: "50 Tasks Completed", description: "Complete 50 tasks total", icon: "checkmark.seal.fill", pointsRequired: 0, isUnlocked: false)
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
        loadTasks()
        loadPoints()
        loadAchievements()
        loadStreakData()
        level = points / 100
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        // Recalculate streak if needed (optional)
        recalculateStreakIfNeeded()
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
                        achievements[index].isUnlocked = true
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
                    achievements[index].isUnlocked = true
                    // Award bonus points for this achievement
                    points += 200
                }
            }
        }
        
        // Also unlock "Getting Started" and "Task Master" based on completed tasks counts
        if totalCompletedTasks >= 1 {
            if let index = achievements.firstIndex(where: { $0.title == "Getting Started" }) {
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    points += 10
                }
            }
        }
        if totalCompletedTasks >= 10 {
            if let index = achievements.firstIndex(where: { $0.title == "Task Master" }) {
                if !achievements[index].isUnlocked {
                    achievements[index].isUnlocked = true
                    points += 90 // To total 100 points as in pointsRequired
                }
            }
        }
    }
    
    private func updatePointsBasedAchievements() {
        // Unlock achievements based on points thresholds
        for index in achievements.indices {
            // For streak and task count achievements with pointsRequired == 0, skip this update
            if achievements[index].pointsRequired > 0 {
                achievements[index].isUnlocked = points >= achievements[index].pointsRequired
            }
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
    }
    
    private func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
    }
    
    private func savePoints() {
        UserDefaults.standard.set(points, forKey: pointsKey)
    }
    
    private func loadPoints() {
        points = UserDefaults.standard.integer(forKey: pointsKey)
    }
    
    private func saveAchievements() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadAchievements() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
    
    private func saveStreakData() {
        UserDefaults.standard.set(currentStreak, forKey: currentStreakKey)
        UserDefaults.standard.set(longestStreak, forKey: longestStreakKey)
        if let date = lastCompletionDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastCompletionDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastCompletionDateKey)
        }
    }
    
    private func loadStreakData() {
        currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        longestStreak = UserDefaults.standard.integer(forKey: longestStreakKey)
        if let timeInterval = UserDefaults.standard.object(forKey: lastCompletionDateKey) as? TimeInterval {
            lastCompletionDate = Date(timeIntervalSince1970: timeInterval)
        } else {
            lastCompletionDate = nil
        }
    }
}

