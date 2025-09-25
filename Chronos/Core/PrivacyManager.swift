import Foundation
import Security
import CryptoKit
import LocalAuthentication

// MARK: - Privacy Manager
/// Handles all privacy-related operations including data encryption, biometric authentication, and privacy settings
class PrivacyManager: ObservableObject {
    static let shared = PrivacyManager()
    
    @Published var isBiometricEnabled: Bool = false
    @Published var isDataEncrypted: Bool = true
    @Published var privacyLevel: PrivacyLevel = .maximum
    
    private let keychain = KeychainManager()
    private let encryptionKey: SymmetricKey
    
    enum PrivacyLevel: String, CaseIterable, Codable {
        case maximum = "Maximum"
        case high = "High"
        case standard = "Standard"
        
        var description: String {
            switch self {
            case .maximum: return "All data encrypted, biometric lock required"
            case .high: return "Data encrypted, optional biometric lock"
            case .standard: return "Basic privacy protection"
            }
        }
    }
    
    private init() {
        // Generate or retrieve encryption key
        self.encryptionKey = Self.getOrCreateEncryptionKey()
        loadPrivacySettings()
    }
    
    // MARK: - Data Encryption/Decryption
    
    func encrypt<T: Codable>(_ data: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(data)
        let sealedBox = try AES.GCM.seal(jsonData, using: encryptionKey)
        return sealedBox.combined!
    }
    
    func decrypt<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    // MARK: - Biometric Authentication
    
    func enableBiometricAuthentication() async throws {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw PrivacyError.biometricNotAvailable
        }
        
        try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                                        localizedReason: "Secure your task data")
        
        await MainActor.run {
            isBiometricEnabled = true
            savePrivacySettings()
        }
    }
    
    func authenticateWithBiometrics() async throws {
        guard isBiometricEnabled else { return }
        
        let context = LAContext()
        try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                        localizedReason: "Access your tasks")
    }
    
    // MARK: - Secure Storage
    
    func storeSecurely<T: Codable>(_ data: T, forKey key: String) throws {
        let encryptedData = try encrypt(data)
        try keychain.store(encryptedData, forKey: key)
    }
    
    func retrieveSecurely<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let encryptedData = try keychain.retrieve(forKey: key) else { return nil }
        return try decrypt(encryptedData, as: type)
    }
    
    // MARK: - Privacy Settings
    
    func setPrivacyLevel(_ level: PrivacyLevel) {
        privacyLevel = level
        savePrivacySettings()
    }
    
    func clearAllData() throws {
        try keychain.deleteAll()
        UserDefaults.standard.removeObject(forKey: "privacySettings")
    }
    
    // MARK: - Private Methods
    
    private static func getOrCreateEncryptionKey() -> SymmetricKey {
        let keyTag = "com.chronos.encryption.key"
        
        // Try to retrieve existing key
        if let keyData = try? KeychainManager().retrieve(forKey: keyTag) {
            let key = SymmetricKey(data: keyData)
            return key
        }
        
        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        let keyData = Data(newKey.withUnsafeBytes { Data($0) })
        try? KeychainManager().store(keyData, forKey: keyTag)
        
        return newKey
    }
    
    private func loadPrivacySettings() {
        if let data = UserDefaults.standard.data(forKey: "privacySettings"),
           let settings = try? JSONDecoder().decode(PrivacySettings.self, from: data) {
            isBiometricEnabled = settings.isBiometricEnabled
            isDataEncrypted = settings.isDataEncrypted
            privacyLevel = settings.privacyLevel
        }
    }
    
    private func savePrivacySettings() {
        let settings = PrivacySettings(
            isBiometricEnabled: isBiometricEnabled,
            isDataEncrypted: isDataEncrypted,
            privacyLevel: privacyLevel
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "privacySettings")
        }
    }
}

// MARK: - Supporting Types

struct PrivacySettings: Codable {
    let isBiometricEnabled: Bool
    let isDataEncrypted: Bool
    let privacyLevel: PrivacyManager.PrivacyLevel
}

enum PrivacyError: LocalizedError {
    case biometricNotAvailable
    case encryptionFailed
    case decryptionFailed
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .keychainError:
            return "Keychain operation failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .biometricNotAvailable:
            return "Please enable biometric authentication in Settings"
        case .encryptionFailed:
            return "Please try again or restart the app"
        case .decryptionFailed:
            return "Please try again or contact support"
        case .keychainError:
            return "Please try again or restart the app"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .biometricNotAvailable:
            return .medium
        case .encryptionFailed, .decryptionFailed:
            return .high
        case .keychainError:
            return .medium
        }
    }
}

// MARK: - Keychain Manager

class KeychainManager {
    private let service = "com.chronos.app"
    
    func store(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw PrivacyError.keychainError
        }
    }
    
    func retrieve(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw PrivacyError.keychainError
        }
        
        return result as? Data
    }
    
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PrivacyError.keychainError
        }
    }
    
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw PrivacyError.keychainError
        }
    }
}
