import SwiftUI

struct TaskStatsView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        List {
            
            Section("Today's Progress") {
                let todayTasks = tasksForToday()
                ProgressBar(completed: Double(todayTasks.completed),
                          total: Double(todayTasks.total))
                StatRow(title: "Completed Today",
                       value: "\(todayTasks.completed)/\(todayTasks.total)")
            }
            
           
            Section("This Week") {
                let weeklyStats = weeklyStats()
                ForEach(0..<7) { dayOffset in
                    if let stat = weeklyStats[dayOffset] {
                        HStack {
                            Text(dayName(for: dayOffset))
                            Spacer()
                            Text("\(stat.completed)/\(stat.total)")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            
          
            Section("Milestones") {
                MilestoneRow(title: "Next Achievement",
                            current: taskManager.points,
                            target: nextAchievementPoints())
                MilestoneRow(title: "Tasks Completed",
                            current: completedTasksCount(),
                            target: 100)
            }
        }
        .navigationTitle("Statistics")
    }
    
    private func tasksForToday() -> (completed: Int, total: Int) {
        let today = Calendar.current.startOfDay(for: Date())
        let todayTasks = taskManager.tasks.filter { task in
            Calendar.current.isDate(task.dueDate, inSameDayAs: today)
        }
        let completed = todayTasks.filter { $0.isCompleted }.count
        return (completed, todayTasks.count)
    }
    
    private func weeklyStats() -> [Int: (completed: Int, total: Int)] {
        var stats: [Int: (completed: Int, total: Int)] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        for dayOffset in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let dayTasks = taskManager.tasks.filter { task in
                    calendar.isDate(task.dueDate, inSameDayAs: date)
                }
                let completed = dayTasks.filter { $0.isCompleted }.count
                stats[dayOffset] = (completed, dayTasks.count)
            }
        }
        return stats
    }
    
    private func dayName(for offset: Int) -> String {
        let date = Calendar.current.date(byAdding: .day,
                                       value: -offset,
                                       to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func nextAchievementPoints() -> Int {
        let nextAchievement = taskManager.achievements
            .first { !$0.isUnlocked }
        return nextAchievement?.pointsRequired ?? taskManager.points
    }
    
    private func completedTasksCount() -> Int {
        taskManager.tasks.filter { $0.isCompleted }.count
    }
}

struct ProgressBar: View {
    let completed: Double
    let total: Double
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return completed / total
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.gray.opacity(0.3))
                
                Rectangle()
                    .fill(.orange)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
    }
}

struct MilestoneRow: View {
    let title: String
    let current: Int
    let target: Int
    
    var progress: Double {
        Double(current) / Double(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            ProgressBar(completed: Double(current),
                       total: Double(target))
            
            Text("\(current)/\(target)")
                .font(.caption)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
} 
