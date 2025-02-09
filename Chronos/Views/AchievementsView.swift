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

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            Image(systemName: achievement.icon)
                .foregroundColor(achievement.isUnlocked ? .orange : .gray)
                .imageScale(.large)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(achievement.isUnlocked ? .orange.opacity(0.2) : .gray.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if !achievement.isUnlocked {
                    Text("\(achievement.pointsRequired) points needed")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
        .opacity(achievement.isUnlocked ? 1 : 0.6)
    }
} 