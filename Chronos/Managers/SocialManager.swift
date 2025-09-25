import Foundation
import SwiftUI
import Combine

// MARK: - Social Models
struct Friend: Identifiable, Codable {
    let id = UUID()
    let username: String
    let displayName: String
    let avatar: String?
    let isOnline: Bool
    let lastActive: Date
    let totalPoints: Int
    let currentStreak: Int
    let achievements: [String]
    let isBlocked: Bool
    let friendshipStatus: FriendshipStatus
    
    enum FriendshipStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case accepted = "Accepted"
        case blocked = "Blocked"
    }
}

struct Challenge: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let type: ChallengeType
    let participants: [UUID] // Friend IDs
    let startDate: Date
    let endDate: Date
    let rules: [String]
    let rewards: [String]
    let isActive: Bool
    let createdBy: UUID
    let winner: UUID?
    
    enum ChallengeType: String, CaseIterable, Codable {
        case dailyTasks = "Daily Tasks"
        case weeklyStreak = "Weekly Streak"
        case pointsRace = "Points Race"
        case achievementHunt = "Achievement Hunt"
        case teamGoal = "Team Goal"
        
        var icon: String {
            switch self {
            case .dailyTasks: return "calendar.badge.checkmark"
            case .weeklyStreak: return "flame.fill"
            case .pointsRace: return "star.fill"
            case .achievementHunt: return "trophy.fill"
            case .teamGoal: return "person.3.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .dailyTasks: return .blue
            case .weeklyStreak: return .orange
            case .pointsRace: return .yellow
            case .achievementHunt: return .purple
            case .teamGoal: return .green
            }
        }
    }
}

struct Leaderboard: Identifiable, Codable {
    let id = UUID()
    let title: String
    let type: LeaderboardType
    let entries: [LeaderboardEntry]
    let period: LeaderboardPeriod
    let lastUpdated: Date
    
    enum LeaderboardType: String, CaseIterable, Codable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case allTime = "All Time"
        case friends = "Friends"
    }
    
    enum LeaderboardPeriod: String, CaseIterable, Codable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisYear = "This Year"
        case allTime = "All Time"
    }
}

struct LeaderboardEntry: Identifiable, Codable {
    let id = UUID()
    let userId: UUID
    let username: String
    let displayName: String
    let avatar: String?
    let score: Int
    let rank: Int
    let badge: String?
    let isCurrentUser: Bool
}

struct Team: Identifiable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let members: [UUID]
    let admins: [UUID]
    let goals: [TeamGoal]
    let isPublic: Bool
    let joinCode: String
    let createdBy: UUID
    let createdAt: Date
    let totalPoints: Int
    let currentStreak: Int
}

struct TeamGoal: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let targetValue: Int
    let currentValue: Int
    let deadline: Date
    let isCompleted: Bool
    let rewards: [String]
}

struct SocialAchievement: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let pointsRequired: Int
    let isUnlocked: Bool
    let unlockedDate: Date?
    let sharedWithFriends: Bool
    let likes: Int
    let comments: [SocialComment]
}

struct SocialComment: Identifiable, Codable {
    let id = UUID()
    let userId: UUID
    let username: String
    let content: String
    let timestamp: Date
    let likes: Int
}

struct SocialPost: Identifiable, Codable {
    let id = UUID()
    let userId: UUID
    let username: String
    let content: String
    let type: PostType
    let timestamp: Date
    let likes: Int
    let comments: [SocialComment]
    let isPublic: Bool
    
    enum PostType: String, CaseIterable, Codable {
        case achievement = "Achievement"
        case milestone = "Milestone"
        case challenge = "Challenge"
        case motivation = "Motivation"
        case tip = "Tip"
    }
}

// MARK: - Social Manager
class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var friends: [Friend] = []
    @Published var challenges: [Challenge] = []
    @Published var leaderboards: [Leaderboard] = []
    @Published var teams: [Team] = []
    @Published var socialAchievements: [SocialAchievement] = []
    @Published var socialPosts: [SocialPost] = []
    @Published var friendRequests: [Friend] = []
    @Published var notifications: [SocialNotification] = []
    
    private let friendsKey = "socialFriends"
    private let challengesKey = "socialChallenges"
    private let leaderboardsKey = "socialLeaderboards"
    private let teamsKey = "socialTeams"
    private let achievementsKey = "socialAchievements"
    private let postsKey = "socialPosts"
    private let requestsKey = "socialFriendRequests"
    private let notificationsKey = "socialNotifications"
    
    private init() {
        loadData()
        generateSampleData()
    }
    
    // MARK: - Friend Management
    func sendFriendRequest(to username: String) {
        let friend = Friend(
            username: username,
            displayName: username,
            avatar: nil,
            isOnline: false,
            lastActive: Date(),
            totalPoints: 0,
            currentStreak: 0,
            achievements: [],
            isBlocked: false,
            friendshipStatus: .pending
        )
        
        friendRequests.append(friend)
        saveData()
    }
    
    func acceptFriendRequest(_ friendId: UUID) {
        if let index = friendRequests.firstIndex(where: { $0.id == friendId }) {
            let friend = friendRequests[index]
            let acceptedFriend = Friend(
                username: friend.username,
                displayName: friend.displayName,
                avatar: friend.avatar,
                isOnline: friend.isOnline,
                lastActive: friend.lastActive,
                totalPoints: friend.totalPoints,
                currentStreak: friend.currentStreak,
                achievements: friend.achievements,
                isBlocked: friend.isBlocked,
                friendshipStatus: .accepted
            )
            
            friends.append(acceptedFriend)
            friendRequests.remove(at: index)
            saveData()
        }
    }
    
    func removeFriend(_ friendId: UUID) {
        friends.removeAll { $0.id == friendId }
        saveData()
    }
    
    func blockUser(_ friendId: UUID) {
        if let index = friends.firstIndex(where: { $0.id == friendId }) {
            let friend = friends[index]
            let blockedFriend = Friend(
                username: friend.username,
                displayName: friend.displayName,
                avatar: friend.avatar,
                isOnline: friend.isOnline,
                lastActive: friend.lastActive,
                totalPoints: friend.totalPoints,
                currentStreak: friend.currentStreak,
                achievements: friend.achievements,
                isBlocked: true,
                friendshipStatus: .blocked
            )
            
            friends[index] = blockedFriend
            saveData()
        }
    }
    
    // MARK: - Challenge Management
    func createChallenge(
        title: String,
        description: String,
        type: Challenge.ChallengeType,
        participants: [UUID],
        duration: TimeInterval,
        rules: [String],
        rewards: [String]
    ) {
        let challenge = Challenge(
            title: title,
            description: description,
            type: type,
            participants: participants,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration),
            rules: rules,
            rewards: rewards,
            isActive: true,
            createdBy: UUID(), // Current user ID
            winner: nil
        )
        
        challenges.append(challenge)
        saveData()
    }
    
    func joinChallenge(_ challengeId: UUID) {
        if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
            // Add current user to participants
            // This would be implemented with actual user ID
            saveData()
        }
    }
    
    func completeChallenge(_ challengeId: UUID) {
        if let index = challenges.firstIndex(where: { $0.id == challengeId }) {
            challenges[index] = Challenge(
                title: challenges[index].title,
                description: challenges[index].description,
                type: challenges[index].type,
                participants: challenges[index].participants,
                startDate: challenges[index].startDate,
                endDate: challenges[index].endDate,
                rules: challenges[index].rules,
                rewards: challenges[index].rewards,
                isActive: false,
                createdBy: challenges[index].createdBy,
                winner: UUID() // Current user ID
            )
            saveData()
        }
    }
    
    // MARK: - Leaderboard Management
    func updateLeaderboard() {
        let friendIds = friends.map { $0.id }
        let entries = friendIds.enumerated().map { index, friendId in
            let friend = friends.first { $0.id == friendId }
            return LeaderboardEntry(
                userId: friendId,
                username: friend?.username ?? "Unknown",
                displayName: friend?.displayName ?? "Unknown",
                avatar: friend?.avatar,
                score: friend?.totalPoints ?? 0,
                rank: index + 1,
                badge: getBadgeForRank(index + 1),
                isCurrentUser: false // Would be true for current user
            )
        }
        
        let leaderboard = Leaderboard(
            title: "Friends Leaderboard",
            type: .friends,
            entries: entries,
            period: .thisWeek,
            lastUpdated: Date()
        )
        
        leaderboards.append(leaderboard)
        saveData()
    }
    
    private func getBadgeForRank(_ rank: Int) -> String? {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return nil
        }
    }
    
    // MARK: - Team Management
    func createTeam(name: String, description: String, isPublic: Bool) {
        let team = Team(
            name: name,
            description: description,
            members: [UUID()], // Current user
            admins: [UUID()], // Current user
            goals: [],
            isPublic: isPublic,
            joinCode: generateJoinCode(),
            createdBy: UUID(), // Current user
            createdAt: Date(),
            totalPoints: 0,
            currentStreak: 0
        )
        
        teams.append(team)
        saveData()
    }
    
    func joinTeam(with joinCode: String) {
        if let team = teams.first(where: { $0.joinCode == joinCode }) {
            // Add current user to team members
            // This would be implemented with actual user ID
            saveData()
        }
    }
    
    private func generateJoinCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in characters.randomElement()! })
    }
    
    // MARK: - Social Achievements
    func shareAchievement(_ achievementId: UUID) {
        if let index = socialAchievements.firstIndex(where: { $0.id == achievementId }) {
            socialAchievements[index] = SocialAchievement(
                title: socialAchievements[index].title,
                description: socialAchievements[index].description,
                icon: socialAchievements[index].icon,
                pointsRequired: socialAchievements[index].pointsRequired,
                isUnlocked: socialAchievements[index].isUnlocked,
                unlockedDate: socialAchievements[index].unlockedDate,
                sharedWithFriends: true,
                likes: socialAchievements[index].likes,
                comments: socialAchievements[index].comments
            )
            saveData()
        }
    }
    
    func likeAchievement(_ achievementId: UUID) {
        if let index = socialAchievements.firstIndex(where: { $0.id == achievementId }) {
            socialAchievements[index] = SocialAchievement(
                title: socialAchievements[index].title,
                description: socialAchievements[index].description,
                icon: socialAchievements[index].icon,
                pointsRequired: socialAchievements[index].pointsRequired,
                isUnlocked: socialAchievements[index].isUnlocked,
                unlockedDate: socialAchievements[index].unlockedDate,
                sharedWithFriends: socialAchievements[index].sharedWithFriends,
                likes: socialAchievements[index].likes + 1,
                comments: socialAchievements[index].comments
            )
            saveData()
        }
    }
    
    // MARK: - Social Posts
    func createPost(content: String, type: SocialPost.PostType, isPublic: Bool = true) {
        let post = SocialPost(
            userId: UUID(), // Current user ID
            username: "You", // Current username
            content: content,
            type: type,
            timestamp: Date(),
            likes: 0,
            comments: [],
            isPublic: isPublic
        )
        
        socialPosts.append(post)
        saveData()
    }
    
    func likePost(_ postId: UUID) {
        if let index = socialPosts.firstIndex(where: { $0.id == postId }) {
            socialPosts[index] = SocialPost(
                userId: socialPosts[index].userId,
                username: socialPosts[index].username,
                content: socialPosts[index].content,
                type: socialPosts[index].type,
                timestamp: socialPosts[index].timestamp,
                likes: socialPosts[index].likes + 1,
                comments: socialPosts[index].comments,
                isPublic: socialPosts[index].isPublic
            )
            saveData()
        }
    }
    
    func commentOnPost(_ postId: UUID, content: String) {
        if let index = socialPosts.firstIndex(where: { $0.id == postId }) {
            let comment = SocialComment(
                userId: UUID(), // Current user ID
                username: "You", // Current username
                content: content,
                timestamp: Date(),
                likes: 0
            )
            
            socialPosts[index] = SocialPost(
                userId: socialPosts[index].userId,
                username: socialPosts[index].username,
                content: socialPosts[index].content,
                type: socialPosts[index].type,
                timestamp: socialPosts[index].timestamp,
                likes: socialPosts[index].likes,
                comments: socialPosts[index].comments + [comment],
                isPublic: socialPosts[index].isPublic
            )
            saveData()
        }
    }
    
    // MARK: - Notifications
    func addNotification(_ notification: SocialNotification) {
        notifications.append(notification)
        saveData()
    }
    
    func markNotificationAsRead(_ notificationId: UUID) {
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index] = SocialNotification(
                type: notifications[index].type,
                title: notifications[index].title,
                message: notifications[index].message,
                timestamp: notifications[index].timestamp,
                isRead: true,
                actionUrl: notifications[index].actionUrl
            )
            saveData()
        }
    }
    
    // MARK: - Data Persistence
    private func saveData() {
        saveFriends()
        saveChallenges()
        saveLeaderboards()
        saveTeams()
        saveSocialAchievements()
        saveSocialPosts()
        saveFriendRequests()
        saveNotifications()
    }
    
    private func loadData() {
        loadFriends()
        loadChallenges()
        loadLeaderboards()
        loadTeams()
        loadSocialAchievements()
        loadSocialPosts()
        loadFriendRequests()
        loadNotifications()
    }
    
    private func saveFriends() {
        if let encoded = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(encoded, forKey: friendsKey)
        }
    }
    
    private func loadFriends() {
        if let data = UserDefaults.standard.data(forKey: friendsKey),
           let decoded = try? JSONDecoder().decode([Friend].self, from: data) {
            friends = decoded
        }
    }
    
    private func saveChallenges() {
        if let encoded = try? JSONEncoder().encode(challenges) {
            UserDefaults.standard.set(encoded, forKey: challengesKey)
        }
    }
    
    private func loadChallenges() {
        if let data = UserDefaults.standard.data(forKey: challengesKey),
           let decoded = try? JSONDecoder().decode([Challenge].self, from: data) {
            challenges = decoded
        }
    }
    
    private func saveLeaderboards() {
        if let encoded = try? JSONEncoder().encode(leaderboards) {
            UserDefaults.standard.set(encoded, forKey: leaderboardsKey)
        }
    }
    
    private func loadLeaderboards() {
        if let data = UserDefaults.standard.data(forKey: leaderboardsKey),
           let decoded = try? JSONDecoder().decode([Leaderboard].self, from: data) {
            leaderboards = decoded
        }
    }
    
    private func saveTeams() {
        if let encoded = try? JSONEncoder().encode(teams) {
            UserDefaults.standard.set(encoded, forKey: teamsKey)
        }
    }
    
    private func loadTeams() {
        if let data = UserDefaults.standard.data(forKey: teamsKey),
           let decoded = try? JSONDecoder().decode([Team].self, from: data) {
            teams = decoded
        }
    }
    
    private func saveSocialAchievements() {
        if let encoded = try? JSONEncoder().encode(socialAchievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    private func loadSocialAchievements() {
        if let data = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([SocialAchievement].self, from: data) {
            socialAchievements = decoded
        }
    }
    
    private func saveSocialPosts() {
        if let encoded = try? JSONEncoder().encode(socialPosts) {
            UserDefaults.standard.set(encoded, forKey: postsKey)
        }
    }
    
    private func loadSocialPosts() {
        if let data = UserDefaults.standard.data(forKey: postsKey),
           let decoded = try? JSONDecoder().decode([SocialPost].self, from: data) {
            socialPosts = decoded
        }
    }
    
    private func saveFriendRequests() {
        if let encoded = try? JSONEncoder().encode(friendRequests) {
            UserDefaults.standard.set(encoded, forKey: requestsKey)
        }
    }
    
    private func loadFriendRequests() {
        if let data = UserDefaults.standard.data(forKey: requestsKey),
           let decoded = try? JSONDecoder().decode([Friend].self, from: data) {
            friendRequests = decoded
        }
    }
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: notificationsKey)
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: notificationsKey),
           let decoded = try? JSONDecoder().decode([SocialNotification].self, from: data) {
            notifications = decoded
        }
    }
    
    // MARK: - Sample Data Generation
    private func generateSampleData() {
        if friends.isEmpty {
            let sampleFriends = [
                Friend(
                    username: "alex_prod",
                    displayName: "Alex",
                    avatar: nil,
                    isOnline: true,
                    lastActive: Date(),
                    totalPoints: 1250,
                    currentStreak: 7,
                    achievements: ["Task Master", "3-Day Streak"],
                    isBlocked: false,
                    friendshipStatus: .accepted
                ),
                Friend(
                    username: "sarah_goals",
                    displayName: "Sarah",
                    avatar: nil,
                    isOnline: false,
                    lastActive: Date().addingTimeInterval(-3600),
                    totalPoints: 980,
                    currentStreak: 3,
                    achievements: ["Getting Started"],
                    isBlocked: false,
                    friendshipStatus: .accepted
                )
            ]
            friends = sampleFriends
        }
        
        if challenges.isEmpty {
            let sampleChallenge = Challenge(
                title: "Weekly Productivity Race",
                description: "Complete 20 tasks this week to win!",
                type: .pointsRace,
                participants: friends.map { $0.id },
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 3600),
                rules: ["Complete tasks to earn points", "Most points wins"],
                rewards: ["100 bonus points", "Exclusive theme"],
                isActive: true,
                createdBy: UUID(),
                winner: nil
            )
            challenges = [sampleChallenge]
        }
    }
}

// MARK: - Social Notification
struct SocialNotification: Identifiable, Codable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let actionUrl: String?
    
    enum NotificationType: String, CaseIterable, Codable {
        case friendRequest = "Friend Request"
        case challengeInvite = "Challenge Invite"
        case achievementUnlock = "Achievement Unlock"
        case leaderboardUpdate = "Leaderboard Update"
        case teamInvite = "Team Invite"
        case postLike = "Post Like"
        case postComment = "Post Comment"
    }
}

