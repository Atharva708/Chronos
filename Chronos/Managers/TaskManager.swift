import Foundation
import SwiftUI
import SwiftUI

class TaskManager: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var points: Int = 0
    @Published var achievements: [Achievement] = Achievement.achievements
    
    private let tasksKey = "saved_tasks"
    private let pointsKey = "saved_points"
    private let achievementsKey = "saved_achievements"
    
    init() {
        loadData()
    }
    
    func addTask(_ task: Task) {
        tasks.append(task)
        saveData()
    }
    
    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveData()
    }
    
    func updateTask(_ task: Task) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveData()
        }
    }
    
    func completeTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        // Only award points if the task wasn't already completed
        if !tasks[index].isCompleted {
            // Update the task
            var updatedTask = task
            updatedTask.isCompleted = true
            updatedTask.completedDate = Date()
            tasks[index] = updatedTask
            
            // Award points
            withAnimation(.spring) {
                points += Task.COMPLETION_POINTS
            }
            
            checkAchievements()
            saveData()
            
            // Debug print to verify points are being awarded
            print("Points awarded! New total: \(points)")
        }
    }
    
    private func checkAchievements() {
        for (index, achievement) in achievements.enumerated() {
            if points >= achievement.pointsRequired && !achievement.isUnlocked {
                achievements[index].isUnlocked = true
            }
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: tasksKey)
        }
        UserDefaults.standard.set(points, forKey: pointsKey)
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([Task].self, from: data) {
            tasks = decoded
        }
        
        points = UserDefaults.standard.integer(forKey: pointsKey)
        
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = decoded
        }
    }
} 