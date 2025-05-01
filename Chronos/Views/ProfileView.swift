import SwiftUI

struct ProfileView: View {
    @ObservedObject var taskManager: TaskManager
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showingThemeStore = false
    
    var completedTasks: Int {
        taskManager.tasks.filter { $0.isCompleted }.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                
                Text("Profile")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading,10)
                
                // Points Card
                VStack(spacing: 8) {
                    Text("\(taskManager.points)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.uiAccent)
                    Text("Total Points")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.horizontal)
                
                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        StatRow(title: "Tasks Completed", value: "\(completedTasks)")
                        StatRow(title: "Completion Rate", value: "\(completionRate)%")
                        StatRow(title: "Current Streak", value: "\(calculateStreak()) days")
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5)
                }
                
                // Theme Store Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Appearance")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Button(action: { showingThemeStore = true }) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.uiAccent)
                            Text("Theme Store")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    }
                }
                .padding(.horizontal)
                
                // Achievements Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Achievements")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(taskManager.achievements) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Profile")
        .background(Color.gray.opacity(0.1))
        .sheet(isPresented: $showingThemeStore) {
            ThemeStoreView()
        }
    }
    
    private var completionRate: Int {
        guard !taskManager.tasks.isEmpty else { return 0 }
        return Int((Double(completedTasks) / Double(taskManager.tasks.count)) * 100)
    }
    
    private func calculateStreak() -> Int {
        // Implement streak calculation logic
        return 0
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .bold()
                .foregroundColor(.orange)
                .padding(.horizontal)
        }
    }
} 
