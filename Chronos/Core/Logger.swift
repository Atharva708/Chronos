import Foundation
import os.log

// MARK: - Logger
/// Production-ready logging system with different levels and privacy protection
class Logger {
    static let shared = Logger()
    
    private let systemLogger = OSLog(subsystem: "com.chronos.app", category: "ChronosApp")
    private let logQueue = DispatchQueue(label: "com.chronos.logger", qos: .utility)
    
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    private init() {}
    
    // MARK: - Public Logging Methods
    
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .error, message: fullMessage, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " - Error: \(error.localizedDescription)"
        }
        log(level: .critical, message: fullMessage, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Privacy-Safe Logging
    
    func logUserAction(_ action: String, category: String = "UserAction") {
        // Log user actions without sensitive data
        info("User Action: \(action)", category: category)
    }
    
    func logTaskOperation(_ operation: String, taskId: String? = nil) {
        let message = taskId != nil ? "Task \(operation): \(taskId!)" : "Task \(operation)"
        info(message, category: "TaskManager")
    }
    
    func logVoiceOperation(_ operation: String, success: Bool) {
        let status = success ? "successful" : "failed"
        info("Voice \(operation): \(status)", category: "VoiceManager")
    }
    
    func logPrivacyEvent(_ event: String) {
        info("Privacy Event: \(event)", category: "Privacy")
    }
    
    // MARK: - Performance Logging
    
    func logPerformance(_ operation: String, duration: TimeInterval) {
        info("Performance: \(operation) took \(String(format: "%.3f", duration))s", category: "Performance")
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, category: String, file: String, function: String, line: Int) {
        logQueue.async {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            let timestamp = DateFormatter.logTimestamp.string(from: Date())
            let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(category)] \(fileName):\(line) \(function) - \(message)"
            
            // Console logging
            print(logMessage)
            
            // System logging
            os_log("%{public}@", log: self.systemLogger, type: level.osLogType, logMessage)
            
            // File logging for production
            self.writeToFile(logMessage)
        }
    }
    
    private func writeToFile(_ message: String) {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logFileURL = documentsPath.appendingPathComponent("chronos.log")
        
        do {
            let data = (message + "\n").data(using: .utf8) ?? Data()
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logFileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            } else {
                try data.write(to: logFileURL)
            }
            
            // Rotate logs if they get too large (> 1MB)
            try rotateLogsIfNeeded(logFileURL)
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func rotateLogsIfNeeded(_ logFileURL: URL) throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
        if let fileSize = attributes[.size] as? Int, fileSize > 1_000_000 { // 1MB
            let rotatedURL = logFileURL.appendingPathExtension("old")
            if FileManager.default.fileExists(atPath: rotatedURL.path) {
                try FileManager.default.removeItem(at: rotatedURL)
            }
            try FileManager.default.moveItem(at: logFileURL, to: rotatedURL)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Log Categories

enum LogCategory {
    static let general = "General"
    static let taskManager = "TaskManager"
    static let voiceManager = "VoiceManager"
    static let privacy = "Privacy"
    static let performance = "Performance"
    static let userAction = "UserAction"
    static let network = "Network"
    static let database = "Database"
    static let ui = "UI"
    static let analytics = "Analytics"
}
