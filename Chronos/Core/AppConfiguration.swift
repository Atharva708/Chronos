import Foundation
import SwiftUI
import _Concurrency

// MARK: - App Configuration
/// Centralized configuration management for production deployment
class AppConfiguration: ObservableObject {
    static let shared = AppConfiguration()
    
    @Published var environment: AppEnvironment = .production
    @Published var features: FeatureFlags = FeatureFlags()
    @Published var analytics: AnalyticsConfiguration = AnalyticsConfiguration()
    @Published var privacy: PrivacyConfiguration = PrivacyConfiguration()
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Environment Management
    
    func setEnvironment(_ environment: AppEnvironment) {
        self.environment = environment
        saveConfiguration()
    }
    
    var isDebugMode: Bool {
        return environment == .development
    }
    
    var isProductionMode: Bool {
        return environment == .production
    }
    
    // MARK: - Feature Flags
    
    func enableFeature(_ feature: Feature) {
        features.enable(feature)
        saveConfiguration()
    }
    
    func disableFeature(_ feature: Feature) {
        features.disable(feature)
        saveConfiguration()
    }
    
    func isFeatureEnabled(_ feature: Feature) -> Bool {
        return features.isEnabled(feature)
    }
    
    // MARK: - Configuration Loading/Saving
    
    private func loadConfiguration() {
        // Load from UserDefaults or remote configuration
        if let data = UserDefaults.standard.data(forKey: "appConfiguration"),
           let config = try? JSONDecoder().decode(AppConfigData.self, from: data) {
            self.environment = config.environment
            self.features = config.features
            self.analytics = config.analytics
            self.privacy = config.privacy
        }
    }
    
    private func saveConfiguration() {
        let config = AppConfigData(
            environment: environment,
            features: features,
            analytics: analytics,
            privacy: privacy
        )
        
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "appConfiguration")
        }
    }
}

// MARK: - Environment Types

enum AppEnvironment: String, CaseIterable, Codable {
    case development = "Development"
    case staging = "Staging"
    case production = "Production"
    
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://dev-api.chronos.app"
        case .staging:
            return "https://staging-api.chronos.app"
        case .production:
            return "https://api.chronos.app"
        }
    }
    
    var analyticsEnabled: Bool {
        switch self {
        case .development:
            return false
        case .staging, .production:
            return true
        }
    }
    
    var loggingLevel: Logger.LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .warning
        }
    }
}

// MARK: - Feature Flags

struct FeatureFlags: Codable {
    private var enabledFeatures: Set<Feature> = []
    
    mutating func enable(_ feature: Feature) {
        enabledFeatures.insert(feature)
    }
    
    mutating func disable(_ feature: Feature) {
        enabledFeatures.remove(feature)
    }
    
    func isEnabled(_ feature: Feature) -> Bool {
        return enabledFeatures.contains(feature)
    }
}

enum Feature: String, CaseIterable, Codable {
    case voiceInput = "Voice Input"
    case socialFeatures = "Social Features"
    case advancedAnalytics = "Advanced Analytics"
    case cloudSync = "Cloud Sync"
    case biometricAuth = "Biometric Authentication"
    case darkMode = "Dark Mode"
    case hapticFeedback = "Haptic Feedback"
    case accessibility = "Accessibility Features"
    case offlineMode = "Offline Mode"
    case exportData = "Data Export"
    
    var isEnabledByDefault: Bool {
        switch self {
        case .voiceInput, .biometricAuth, .darkMode, .hapticFeedback, .accessibility:
            return true
        case .socialFeatures, .advancedAnalytics, .cloudSync, .offlineMode, .exportData:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .voiceInput:
            return "Enable voice input for task creation"
        case .socialFeatures:
            return "Enable social features and sharing"
        case .advancedAnalytics:
            return "Enable detailed analytics tracking"
        case .cloudSync:
            return "Enable cloud synchronization"
        case .biometricAuth:
            return "Enable biometric authentication"
        case .darkMode:
            return "Enable dark mode support"
        case .hapticFeedback:
            return "Enable haptic feedback"
        case .accessibility:
            return "Enable accessibility features"
        case .offlineMode:
            return "Enable offline functionality"
        case .exportData:
            return "Enable data export functionality"
        }
    }
}

// MARK: - Analytics Configuration

struct AnalyticsConfiguration: Codable {
    var isEnabled: Bool = true
    var trackUserActions: Bool = true
    var trackPerformance: Bool = true
    var trackErrors: Bool = true
    var trackPrivacyEvents: Bool = false
    var anonymizeData: Bool = true
    
    var retentionPeriod: Int = 30 // days
    var batchSize: Int = 100
    var flushInterval: TimeInterval = 300 // 5 minutes
}

// MARK: - Privacy Configuration

struct PrivacyConfiguration: Codable {
    var dataEncryption: Bool = true
    var biometricProtection: Bool = false
    var analyticsOptIn: Bool = true
    var crashReporting: Bool = true
    var performanceMonitoring: Bool = true
    
    var dataRetentionPeriod: Int = 365 // days
    var autoDeleteCompletedTasks: Bool = false
    var autoDeleteCompletedTasksAfter: Int = 30 // days
}

// MARK: - Configuration Data

struct AppConfigData: Codable {
    let environment: AppEnvironment
    let features: FeatureFlags
    let analytics: AnalyticsConfiguration
    let privacy: PrivacyConfiguration
}

// MARK: - Remote Configuration

class RemoteConfigurationManager: ObservableObject {
    static let shared = RemoteConfigurationManager()
    
    @Published var isConnected = false
    @Published var lastUpdate: Date?
    
    private let logger = Logger.shared
    
    private init() {}
    
    func fetchRemoteConfiguration() async {
        do {
            // In a real implementation, this would fetch from a remote server
            logger.info("Fetching remote configuration", category: LogCategory.general)
            
            // Simulate network delay
            try await _Concurrency.Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                self.isConnected = true
                self.lastUpdate = Date()
            }
            
            logger.info("Remote configuration updated", category: LogCategory.general)
        } catch {
            logger.error("Failed to fetch remote configuration", error: error, category: LogCategory.general)
        }
    }
    
    func updateFeatureFlags(_ flags: [Feature: Bool]) {
        let config = AppConfiguration.shared
        
        for (feature, isEnabled) in flags {
            if isEnabled {
                config.enableFeature(feature)
            } else {
                config.disableFeature(feature)
            }
        }
    }
}

// MARK: - App Version Management

struct AppVersion {
    let major: Int
    let minor: Int
    let patch: Int
    let build: Int
    
    var versionString: String {
        return "\(major).\(minor).\(patch)"
    }
    
    var fullVersionString: String {
        return "\(major).\(minor).\(patch) (\(build))"
    }
    
    static let current = AppVersion(major: 1, minor: 0, patch: 0, build: 1)
}

// MARK: - Build Configuration

struct BuildConfiguration {
    static let isDebug = _isDebugAssertConfiguration()
    static let isRelease = !isDebug
    static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    static let isAppStore = Bundle.main.appStoreReceiptURL?.lastPathComponent == "receipt"
    
    static var environment: AppEnvironment {
        if isDebug {
            return .development
        } else if isTestFlight {
            return .staging
        } else {
            return .production
        }
    }
}
