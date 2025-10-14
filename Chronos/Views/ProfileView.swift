import SwiftUI

struct ProfileView: View {
    @ObservedObject var taskManager: TaskManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingThemeStore = false
    @State private var animateAchievementUnlock = false
    @State private var animateLevelUp = false

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

                // Points Card with Level Display
                VStack(spacing: 8) {
                    Text("\(taskManager.points)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.uiAccent)

                    Text("Total Points")
                        .font(.headline)
                        .foregroundColor(.gray)

                    // Level display below points
                    Text("Level \(taskManager.level)")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.uiAccent.opacity(0.8))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.horizontal)
                .scaleEffect(animateLevelUp ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: animateLevelUp)

                // Stats Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 16) {
                        StatRow(title: "Current Streak", value: "\(taskManager.currentStreak) days")
                        StatRow(title: "Longest Streak", value: "\(taskManager.longestStreak) days")
                        
                        // Level Progress with progress bar
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Level Progress")
                                Spacer()
                                Text("\(currentPointsInLevel) / \(totalPointsForLevel)")
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                            ProgressView(value: levelProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.orange))
                                .frame(height: 6)
                                .clipShape(RoundedRectangle(cornerRadius: 3))
                        }
                        .padding(.horizontal)
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
                            .scaleEffect(achievement.isUnlocked ? 1.05 : 1.0)
                            .animation(
                                achievement.isUnlocked ?
                                    Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                                value: achievement.isUnlocked
                            )
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
        .onChange(of: taskManager.level) { _ in
            // Placeholder for celebratory feedback on level up
            animateLevelUpAnimation()
        }
        .onChange(of: taskManager.currentStreak) { _ in
            // Placeholder for celebratory feedback on new streak achievement
            // animateStreakAchievement()
        }
        .onChange(of: taskManager.achievements) { newValue in
            if newValue.contains(where: { $0.isUnlocked }) {
                animateAchievementUnlockAnimation()
            }
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

    private var pointsPerLevel: Int { 100 }
    private var currentPointsInLevel: Int {
        let startOfLevel = (taskManager.points / pointsPerLevel) * pointsPerLevel
        return max(taskManager.points - startOfLevel, 0)
    }
    private var totalPointsForLevel: Int { pointsPerLevel }

    private var levelProgress: Double {
        guard totalPointsForLevel > 0 else { return 0 }
        return min(max(Double(currentPointsInLevel) / Double(totalPointsForLevel), 0), 1)
    }

    private func animateAchievementUnlockAnimation() {
        // Placeholder for achievement unlock animation, e.g. confetti or scale effect
        // This would be implemented with an animation view or particle system
    }

    private func animateLevelUpAnimation() {
        animateLevelUp = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateLevelUp = false
        }
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

struct AchievementRow: View {
    let achievement: Achievement

    @State private var animate = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(achievement.isUnlocked ? .orange : .gray.opacity(0.5))
                .scaleEffect(achievement.isUnlocked ? (animate ? 1.1 : 1.0) : 1.0)
                .animation(
                    achievement.isUnlocked ?
                        Animation.easeInOut(duration: 1).repeatForever(autoreverses: true) : .default,
                    value: animate
                )
                .onAppear {
                    if achievement.isUnlocked {
                        animate = true
                    }
                }

            VStack(alignment: .leading) {
                Text(achievement.title)
                    .fontWeight(achievement.isUnlocked ? .bold : .regular)
                    .foregroundColor(.primary)
                if !achievement.isUnlocked {
                    Text("Locked")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.03), radius: 3)
    }
}
