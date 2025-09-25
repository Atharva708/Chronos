import Foundation
import SwiftUI
import Combine

// MARK: - Base Manager Protocol
protocol BaseManager: ObservableObject {
    associatedtype DataType: Codable & Identifiable
    
    var data: [DataType] { get set }
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    
    func saveData() async throws
    func loadData() async throws
    func validateData() -> Bool
}

// MARK: - Manager Error Types
enum ManagerError: LocalizedError {
    case dataCorrupted
    case saveFailed
    case loadFailed
    case validationFailed
    case networkError(Error)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .dataCorrupted:
            return "Data is corrupted and cannot be loaded"
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .validationFailed:
            return "Data validation failed"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Base Manager Implementation
class BaseManagerImpl<DataType: Codable & Identifiable>: ObservableObject {
    @Published var data: [DataType] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let storageKey: String
    private let queue = DispatchQueue(label: "com.chronos.manager", qos: .userInitiated)
    
    init(storageKey: String) {
        self.storageKey = storageKey
    }
    
    // MARK: - Data Operations
    func saveData() async throws {
        await MainActor.run { isLoading = true }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            await MainActor.run { 
                isLoading = false
                errorMessage = nil
            }
        } catch {
            await MainActor.run { 
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw ManagerError.saveFailed
        }
    }
    
    func loadData() async throws {
        await MainActor.run { isLoading = true }
        
        do {
            if let savedData = UserDefaults.standard.data(forKey: storageKey) {
                let decoded = try JSONDecoder().decode([DataType].self, from: savedData)
                await MainActor.run { 
                    self.data = decoded
                    isLoading = false
                    errorMessage = nil
                }
            } else {
                await MainActor.run { 
                    data = []
                    isLoading = false
                    errorMessage = nil
                }
            }
        } catch {
            await MainActor.run { 
                isLoading = false
                errorMessage = error.localizedDescription
            }
            throw ManagerError.loadFailed
        }
    }
    
    func validateData() -> Bool {
        return !data.isEmpty || data.allSatisfy { _ in true }
    }
    
    // MARK: - CRUD Operations
    func add(_ item: DataType) async throws {
        await MainActor.run { data.append(item) }
        try await saveData()
    }
    
    func update(_ item: DataType) async throws {
        guard let index = data.firstIndex(where: { $0.id == item.id }) else {
            throw ManagerError.validationFailed
        }
        
        await MainActor.run { data[index] = item }
        try await saveData()
    }
    
    func delete(_ item: DataType) async throws {
        await MainActor.run { data.removeAll { $0.id == item.id } }
        try await saveData()
    }
    
    func delete(at indexSet: IndexSet) async throws {
        await MainActor.run { data.remove(atOffsets: indexSet) }
        try await saveData()
    }
    
    // MARK: - Search and Filter
    func find(by id: DataType.ID) -> DataType? {
        return data.first { $0.id == id }
    }
    
    func filter(_ predicate: @escaping (DataType) -> Bool) -> [DataType] {
        return data.filter(predicate)
    }
    
    // MARK: - Batch Operations
    func batchUpdate(_ updates: [DataType]) async throws {
        await MainActor.run {
            for update in updates {
                if let index = data.firstIndex(where: { $0.id == update.id }) {
                    data[index] = update
                }
            }
        }
        try await saveData()
    }
    
    func batchDelete(_ items: [DataType]) async throws {
        let ids = Set(items.map { $0.id })
        await MainActor.run { data.removeAll { ids.contains($0.id) } }
        try await saveData()
    }
}

// MARK: - Analytics Protocol
protocol AnalyticsProvider {
    func trackEvent(_ event: String, properties: [String: Any]?)
    func trackError(_ error: Error, context: String)
}

// MARK: - Analytics Implementation
class BaseAnalyticsProvider: AnalyticsProvider {
    static let shared = BaseAnalyticsProvider()
    
    private init() {}
    
    func trackEvent(_ event: String, properties: [String: Any]? = nil) {
        // Implement analytics tracking
        print("📊 Event: \(event), Properties: \(properties ?? [:])")
    }
    
    func trackError(_ error: Error, context: String) {
        // Implement error tracking
        print("❌ Error in \(context): \(error.localizedDescription)")
    }
}

// MARK: - Notification Protocol
protocol NotificationProvider {
    func scheduleNotification(title: String, body: String, date: Date)
    func cancelNotification(identifier: String)
}


