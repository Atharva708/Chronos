import SwiftUI

struct AchievementsView: View {
    @StateObject private var taskManager = TaskManager()
    
    var body: some View {
        List {
            ForEach(taskManager.achievements) { achievement in
                AchievementRow(achievement: achievement)
            }
        }
        .navigationTitle("Achievements")
    }
}

