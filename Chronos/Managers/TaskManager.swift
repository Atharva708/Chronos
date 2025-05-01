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
        }
    }
    @Published var achievements: [Achievement] = [
        Achievement(title: "Getting Started", description: "Complete your first task", icon: "star.fill", pointsRequired: 10, isUnlocked: false),
        Achievement(title: "Task Master", description: "Complete 10 tasks", icon: "star.circle.fill", pointsRequired: 100, isUnlocked: false),
        Achievement(title: "Productivity Pro", description: "Reach 1000 points", icon: "medal.star", pointsRequired: 1000, isUnlocked: false),
        Achievement(title: "Productivity King", description: "Reach 10000 points", icon: "crown.fill", pointsRequired: 10000, isUnlocked: false),
        Achievement(title: "Productivity Legend", description: "Reach 100000 points", icon: "trophy.fill", pointsRequired: 100000, isUnlocked: false)
    
    ] {
        didSet {
            saveAchievements()
        }
    }
    
    private let tasksKey = "savedTasks"
    private let pointsKey = "savedPoints"
    private let achievementsKey = "savedAchievements"
    
    init() {
        loadTasks()
        loadPoints()
        loadAchievements()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
    
    func toggleTaskCompletion(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tasks[index].completedDate = tasks[index].isCompleted ? Date() : nil
        
        if tasks[index].isCompleted {
            points += Task.COMPLETION_POINTS
        } else {
            points = max(points - Task.COMPLETION_POINTS, 0)
        }
        
        achievements = achievements.map { achievement in
            var updated = achievement
            updated.isUnlocked = points >= achievement.pointsRequired
            return updated
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
}
