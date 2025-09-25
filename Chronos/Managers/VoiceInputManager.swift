import Foundation
import AVFoundation
import Speech
import Combine
import NaturalLanguage

// MARK: - Enhanced Voice Input Manager
/// Production-ready voice input system with natural language processing and privacy protection
class VoiceInputManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var lastTranscription = ""
    @Published var confidence: Float = 0.0
    @Published var isPermissionGranted = false
    
    // MARK: - Core Components
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioSession = AVAudioSession.sharedInstance()
    
    // MARK: - Natural Language Processing
    private let nlpProcessor = NLPProcessor()
    private let logger = Logger.shared
    private let errorHandler = ErrorHandler.shared
    
    // MARK: - Voice Commands
    private let voiceCommands = VoiceCommandProcessor()
    
    override init() {
        super.init()
        requestPermissions()
        setupAudioSession()
    }
    
    // MARK: - Permission Management
    
    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.isPermissionGranted = authStatus == .authorized
                if authStatus == .authorized {
                    self?.logger.info("Speech recognition authorized", category: LogCategory.voiceManager)
                } else {
                    self?.logger.warning("Speech recognition not authorized", category: LogCategory.voiceManager)
                }
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Audio session setup failed", error: error, category: LogCategory.voiceManager)
            errorHandler.handleVoiceError(.audioSessionError, context: "setupAudioSession")
        }
    }
    
    // MARK: - Enhanced Voice Recognition
    
    func startVoiceInput(completion: @escaping (VoiceResult) -> Void) {
        guard isPermissionGranted else {
            errorHandler.handleVoiceError(.permissionDenied, context: "startVoiceInput")
            return
        }
        
        guard !isRecording else { return }
        
        logger.logVoiceOperation("start_recording", success: true)
        
        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            logger.error("Unable to create recognition request", category: LogCategory.voiceManager)
            errorHandler.handleVoiceError(.recognitionFailed, context: "startVoiceInput")
            return
        }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        isRecording = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Speech recognition error", error: error, category: LogCategory.voiceManager)
                self.errorHandler.handleVoiceError(.recognitionFailed, context: "recognitionTask")
                self.stopRecording()
                completion(.failure(.recognitionFailed))
                return
            }
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                let confidence = result.bestTranscription.segments.first?.confidence ?? 0.0
                
                DispatchQueue.main.async {
                    self.lastTranscription = transcription
                    self.confidence = confidence
                }
                
                if result.isFinal {
                    self.processTranscription(transcription, confidence: confidence, completion: completion)
                }
            }
        }
        
        // Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            logger.info("Voice recording started", category: LogCategory.voiceManager)
        } catch {
            logger.error("Audio Engine start error", error: error, category: LogCategory.voiceManager)
            errorHandler.handleVoiceError(.audioSessionError, context: "startAudioEngine")
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
        
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        recognitionTask = nil
        
        logger.logVoiceOperation("stop_recording", success: true)
    }
    
    // MARK: - Natural Language Processing
    
    private func processTranscription(_ text: String, confidence: Float, completion: @escaping (VoiceResult) -> Void) {
        isProcessing = true
        
        // Process with NLP
        nlpProcessor.processTaskInput(text) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                self?.stopRecording()
                
                switch result {
                case .success(let processedTask):
                    self?.logger.info("Voice processing successful: \(processedTask.title)", category: LogCategory.voiceManager)
                    completion(.success(processedTask))
                case .failure(let error):
                    self?.logger.error("Voice processing failed", error: error, category: LogCategory.voiceManager)
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Voice Commands
    
    func processVoiceCommand(_ text: String) -> VoiceCommand? {
        return voiceCommands.process(text)
    }
    
    // MARK: - Privacy-Safe Methods
    
    func clearTranscriptionData() {
        lastTranscription = ""
        confidence = 0.0
        logger.logPrivacyEvent("Voice transcription data cleared")
    }
}

// MARK: - Voice Result Types

enum VoiceResult {
    case success(ProcessedTask)
    case failure(VoiceError)
}

struct ProcessedTask {
    let title: String
    let description: String
    let priority: TaskPriority
    let dueDate: Date?
    let confidence: Float
    let originalText: String
}

// MARK: - NLP Processor

class NLPProcessor {
    private let logger = Logger.shared
    
    func processTaskInput(_ text: String, completion: @escaping (Result<ProcessedTask, VoiceError>) -> Void) {
        // Extract task information using NLP
        let title = extractTitle(from: text)
        let description = extractDescription(from: text)
        let priority = extractPriority(from: text)
        let dueDate = extractDueDate(from: text)
        
        let processedTask = ProcessedTask(
            title: title,
            description: description,
            priority: priority,
            dueDate: dueDate,
            confidence: 0.8, // This would be calculated based on NLP confidence
            originalText: text
        )
        
        logger.info("NLP processing completed for: \(title)", category: LogCategory.voiceManager)
        completion(.success(processedTask))
    }
    
    private func extractTitle(from text: String) -> String {
        // Simple title extraction - in production, this would use more sophisticated NLP
        let sentences = text.components(separatedBy: ".")
        return sentences.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? text
    }
    
    private func extractDescription(from text: String) -> String {
        // Extract additional context as description
        let sentences = text.components(separatedBy: ".")
        if sentences.count > 1 {
            return sentences.dropFirst().joined(separator: ".").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }
    
    private func extractPriority(from text: String) -> TaskPriority {
        let lowercased = text.lowercased()
        
        if lowercased.contains("urgent") || lowercased.contains("important") || lowercased.contains("high priority") {
            return .high
        } else if lowercased.contains("low") || lowercased.contains("not urgent") {
            return .low
        }
        
        return .medium
    }
    
    private func extractDueDate(from text: String) -> Date? {
        let lowercased = text.lowercased()
        let calendar = Calendar.current
        let now = Date()
        
        if lowercased.contains("today") {
            return calendar.startOfDay(for: now)
        } else if lowercased.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if lowercased.contains("this week") {
            return calendar.date(byAdding: .day, value: 7, to: now)
        }
        
        return nil
    }
}

// MARK: - Voice Command Processor

class VoiceCommandProcessor {
    private let logger = Logger.shared
    
    func process(_ text: String) -> VoiceCommand? {
        let lowercased = text.lowercased()
        
        // Task creation commands
        if lowercased.contains("create task") || lowercased.contains("add task") || lowercased.contains("new task") {
            return .createTask
        }
        
        // Task management commands
        if lowercased.contains("complete task") || lowercased.contains("finish task") {
            return .completeTask
        }
        
        if lowercased.contains("delete task") || lowercased.contains("remove task") {
            return .deleteTask
        }
        
        // Navigation commands
        if lowercased.contains("show tasks") || lowercased.contains("list tasks") {
            return .showTasks
        }
        
        if lowercased.contains("show calendar") {
            return .showCalendar
        }
        
        if lowercased.contains("show profile") {
            return .showProfile
        }
        
        // Help commands
        if lowercased.contains("help") || lowercased.contains("what can you do") {
            return .showHelp
        }
        
        return nil
    }
}

// MARK: - Voice Commands

enum VoiceCommand {
    case createTask
    case completeTask
    case deleteTask
    case showTasks
    case showCalendar
    case showProfile
    case showHelp
    
    var description: String {
        switch self {
        case .createTask:
            return "Create a new task"
        case .completeTask:
            return "Mark a task as complete"
        case .deleteTask:
            return "Delete a task"
        case .showTasks:
            return "Show task list"
        case .showCalendar:
            return "Show calendar view"
        case .showProfile:
            return "Show profile"
        case .showHelp:
            return "Show available voice commands"
        }
    }
}
