import Foundation
import SwiftUI

// MARK: - Error Handler
/// Centralized error handling system for production-ready error management
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    private let logger = Logger.shared
    
    private init() {}
    
    // MARK: - Error Handling Methods
    
    func handle(_ error: Error, context: String = "", showToUser: Bool = true) {
        let appError = AppError.from(error, context: context)
        
        logger.error("Error occurred", error: error, category: LogCategory.general)
        
        if showToUser {
            DispatchQueue.main.async {
                self.currentError = appError
                self.isShowingError = true
            }
        }
    }
    
    func handle(_ appError: AppError, showToUser: Bool = true) {
        logger.error("App Error: \(appError.localizedDescription)", category: LogCategory.general)
        
        if showToUser {
            DispatchQueue.main.async {
                self.currentError = appError
                self.isShowingError = true
            }
        }
    }
    
    func dismissError() {
        currentError = nil
        isShowingError = false
    }
    
    // MARK: - Specific Error Handlers
    
    func handleTaskError(_ error: TaskError, context: String = "") {
        let appError = AppError.taskError(error, context: context)
        handle(appError)
    }
    
    func handleVoiceError(_ error: VoiceError, context: String = "") {
        let appError = AppError.voiceError(error, context: context)
        handle(appError)
    }
    
    func handlePrivacyError(_ error: PrivacyError, context: String = "") {
        let appError = AppError.privacyError(error, context: context)
        handle(appError)
    }
    
    func handleNetworkError(_ error: NetworkError, context: String = "") {
        let appError = AppError.networkError(error, context: context)
        handle(appError)
    }
}

// MARK: - App Error Types

enum AppError: LocalizedError, Identifiable {
    case taskError(TaskError, context: String)
    case voiceError(VoiceError, context: String)
    case privacyError(PrivacyError, context: String)
    case networkError(NetworkError, context: String)
    case unknown(Error, context: String)
    
    var id: String { localizedDescription }
    
    var errorDescription: String? {
        switch self {
        case .taskError(let error, let context):
            return "Task Error: \(error.localizedDescription) (\(context))"
        case .voiceError(let error, let context):
            return "Voice Error: \(error.localizedDescription) (\(context))"
        case .privacyError(let error, let context):
            return "Privacy Error: \(error.localizedDescription) (\(context))"
        case .networkError(let error, let context):
            return "Network Error: \(error.localizedDescription) (\(context))"
        case .unknown(let error, let context):
            return "Unknown Error: \(error.localizedDescription) (\(context))"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .taskError(let error, _):
            return error.recoverySuggestion
        case .voiceError(let error, _):
            return error.recoverySuggestion
        case .privacyError(let error, _):
            return error.recoverySuggestion
        case .networkError(let error, _):
            return error.recoverySuggestion
        case .unknown(_, _):
            return "Please try again or contact support if the problem persists."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .taskError(let error, _):
            return error.severity
        case .voiceError(let error, _):
            return error.severity
        case .privacyError(let error, _):
            return error.severity
        case .networkError(let error, _):
            return error.severity
        case .unknown(_, _):
            return .medium
        }
    }
    
    static func from(_ error: Error, context: String) -> AppError {
        if let taskError = error as? TaskError {
            return .taskError(taskError, context: context)
        } else if let voiceError = error as? VoiceError {
            return .voiceError(voiceError, context: context)
        } else if let privacyError = error as? PrivacyError {
            return .privacyError(privacyError, context: context)
        } else if let networkError = error as? NetworkError {
            return .networkError(networkError, context: context)
        } else {
            return .unknown(error, context: context)
        }
    }
}

// MARK: - Specific Error Types

enum TaskError: LocalizedError {
    case taskNotFound
    case invalidTaskData
    case saveFailed
    case loadFailed
    case deleteFailed
    case duplicateTask
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task not found"
        case .invalidTaskData:
            return "Invalid task data provided"
        case .saveFailed:
            return "Failed to save task"
        case .loadFailed:
            return "Failed to load tasks"
        case .deleteFailed:
            return "Failed to delete task"
        case .duplicateTask:
            return "A task with this title already exists"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .taskNotFound:
            return "The task may have been deleted. Please refresh the list."
        case .invalidTaskData:
            return "Please check your input and try again."
        case .saveFailed:
            return "Please try saving again. If the problem persists, restart the app."
        case .loadFailed:
            return "Please restart the app to reload your tasks."
        case .deleteFailed:
            return "Please try deleting the task again."
        case .duplicateTask:
            return "Please choose a different title for your task."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .taskNotFound, .duplicateTask:
            return .low
        case .invalidTaskData:
            return .low
        case .saveFailed, .loadFailed, .deleteFailed:
            return .high
        }
    }
}

enum VoiceError: LocalizedError {
    case permissionDenied
    case recognitionFailed
    case audioSessionError
    case transcriptionError
    case microphoneUnavailable
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .recognitionFailed:
            return "Speech recognition failed"
        case .audioSessionError:
            return "Audio session error"
        case .transcriptionError:
            return "Failed to transcribe speech"
        case .microphoneUnavailable:
            return "Microphone is not available"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Please enable microphone access in Settings > Privacy & Security > Microphone"
        case .recognitionFailed:
            return "Please try speaking more clearly or check your internet connection"
        case .audioSessionError:
            return "Please restart the app and try again"
        case .transcriptionError:
            return "Please try speaking again or use text input instead"
        case .microphoneUnavailable:
            return "Please check if your microphone is working and try again"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .permissionDenied, .microphoneUnavailable:
            return .medium
        case .recognitionFailed, .audioSessionError, .transcriptionError:
            return .low
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError
    case invalidResponse
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError:
            return "Server error occurred"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited:
            return "Too many requests, please wait"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Please check your internet connection and try again"
        case .timeout:
            return "Please try again in a moment"
        case .serverError:
            return "The server is experiencing issues. Please try again later"
        case .invalidResponse:
            return "Please try again or contact support"
        case .rateLimited:
            return "Please wait a moment before trying again"
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout:
            return .medium
        case .serverError, .invalidResponse:
            return .high
        case .rateLimited:
            return .low
        }
    }
}

enum ErrorSeverity {
    case low
    case medium
    case high
    case critical
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: severityIcon)
                .font(.system(size: 50))
                .foregroundColor(severityColor)
            
            Text("Oops!")
                .font(.title2.bold())
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .multilineTextAlignment(.center)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button("OK") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var severityIcon: String {
        switch error.severity {
        case .low: return "exclamationmark.triangle"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "xmark.circle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch error.severity {
        case .low: return .yellow
        case .medium: return .orange
        case .high: return .red
        case .critical: return .red
        }
    }
}
