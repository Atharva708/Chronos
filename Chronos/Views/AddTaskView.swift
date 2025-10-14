import Foundation
import SwiftUI
import Speech
import AVFoundation
import FoundationModels // Added for Foundation Model integration

// MARK: - VoiceInputManager: Real speech-to-text manager using SFSpeechRecognizer and AVAudioEngine
class VoiceInputManager: NSObject, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    @Published var isRecording = false
    
    override init() {
        super.init()
        requestAuthorization()
    }
    
    private func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                break // authorized
            case .denied, .restricted, .notDetermined:
                break // handle accordingly if needed
            @unknown default:
                break
            }
        }
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // handle permission if needed
        }
    }
    
    /// Starts recording and transcribing speech to text asynchronously.
    /// The completion handler is called when the user stops recording or an error occurs.
    func transcribeSpeechToText(completion: @escaping (String) -> Void) {
        if isRecording {
            stopRecording { resultText in
                completion(resultText)
            }
        } else {
            startRecording { resultText in
                completion(resultText)
            }
        }
    }
    
    private func startRecording(completion: @escaping (String) -> Void) {
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            completion("")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            completion("")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                // Partial or final transcription
                if result.isFinal {
                    self.stopRecording { _ in
                        completion(result.bestTranscription.formattedString)
                    }
                }
            }
            
            if error != nil {
                self.stopRecording { _ in
                    completion("")
                }
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
            }
        } catch {
            completion("")
            return
        }
    }
    
    private func stopRecording(completion: @escaping (String) -> Void) {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
        // Small delay to ensure recognitionTask finishes properly before callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion("") // When stopped manually, no new result is sent here
        }
    }
}

/// Privacy Usage Description comments for Info.plist:
/// NSMicrophoneUsageDescription = "This app requires access to the microphone to enable speech-to-text input."
/// NSSpeechRecognitionUsageDescription = "This app uses speech recognition to convert your voice into text."

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var selectedPriority = TaskPriority.medium
    @State private var isAnimating = false
    
    @ObservedObject private var voiceInputManager = VoiceInputManager()
    
    // New state for AI subtasks suggestion as array of strings
    @State private var suggestedSubtasks: [String] = []
    // State to track loading state when breaking down with AI
    @State private var isBreakingDown = false
    // State to track which subtasks are checked/selected by index
    @State private var checkedSubtasks: Set<Int> = []
    // State to hold error messages from subtasks generation
    @State private var subtaskError: String? = nil
    
    // States for calendar sync success/error alerts
    @State private var showCalendarSyncSuccess = false
    @State private var showCalendarSyncError = false
    
    let gradientColors = [Color.orange, Color.pink]
    private var backgroundGradientColors: [Color] { [Color.orange.opacity(0.1), Color.pink.opacity(0.1)] }
    private let inputBackground = Color.white.opacity(0.8)
    
    private var isTitleEmpty: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isDescriptionEmpty: Bool { description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    var body: some View {
        NavigationView {
            ZStack {
                BackgroundGradientView(colors: backgroundGradientColors)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        TitleInputSection(title: $title, voiceInputManager: voiceInputManager, isAnimating: isAnimating, inputBackground: inputBackground)
                        
                        // Description
                        DescriptionInputSection(description: $description, voiceInputManager: voiceInputManager, isAnimating: isAnimating, inputBackground: inputBackground)
                        
                        // Break down button
                        BreakDownButtonSection(isBreakingDown: isBreakingDown, isTitleEmpty: isTitleEmpty, isDescriptionEmpty: isDescriptionEmpty, gradientColors: gradientColors, isAnimating: isAnimating, breakDownAction: breakDownTaskWithAI)
                        
                        // Subtasks suggestions
                        SubtasksSection(suggestedSubtasks: suggestedSubtasks, checkedSubtasks: $checkedSubtasks, subtaskError: subtaskError, gradientColors: gradientColors, isAnimating: isAnimating, addCheckedSubtasks: addCheckedSubtasks)
                        
                        // Priority selection
                        PrioritySelectionSection(selectedPriority: $selectedPriority, isAnimating: isAnimating)
                        
                        // Due date
                        DueDateSection(dueDate: $dueDate, isAnimating: isAnimating, inputBackground: inputBackground)
                        
                        // Add + Sync buttons
                        AddAndSyncButtonsSection(title: title, gradientColors: gradientColors, isAnimating: isAnimating, addTask: addTask, canSync: !taskManager.tasks.isEmpty, syncAction: {
                            guard let lastTask = taskManager.tasks.last else { return }
                            CalendarSyncManager.shared.addTaskToCalendar(task: lastTask) { success, error in
                                DispatchQueue.main.async {
                                    if success {
                                        showCalendarSyncSuccess = true
                                    } else {
                                        showCalendarSyncError = true
                                    }
                                }
                            }
                        })
                    }
                    .padding()
                }
            }
            .navigationTitle("Schedule Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray)
                            .imageScale(.large)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(duration: 0.8)) {
                    isAnimating = true
                }
            }
            .alert("Success", isPresented: $showCalendarSyncSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The task was successfully synced to your calendar.")
            }
            .alert("Error", isPresented: $showCalendarSyncError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to sync the task to your calendar. Please try again.")
            }
        }
    }
    
    /// Async function stub that generates simple subtasks locally to avoid unsupported API usage
    private func breakDownTaskWithAI() {
        let taskText = !title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty ? title : description
        guard !taskText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else { return }
        DispatchQueue.main.async {
            isBreakingDown = true
            suggestedSubtasks = []
            checkedSubtasks = []
            subtaskError = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let base = taskText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let generated = [
                "Define the goal for: \(base)",
                "List resources needed for: \(base)",
                "Break into smaller steps for: \(base)",
                "Schedule time for: \(base)",
                "Review and adjust: \(base)"
            ]
            suggestedSubtasks = generated
            checkedSubtasks = Set(generated.indices)
            isBreakingDown = false
        }
    }
    
    /// Adds checked subtasks as new tasks to taskManager
    private func addCheckedSubtasks() {
        for index in checkedSubtasks {
            guard index < suggestedSubtasks.count else { continue }
            let subtaskTitle = suggestedSubtasks[index].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !subtaskTitle.isEmpty {
                let newTask = Task(
                    title: subtaskTitle,
                    description: "",
                    dueDate: max(dueDate, Date()),
                    isCompleted: false,
                    priority: .low // default priority for subtasks
                )
                taskManager.addTask(newTask)
            }
        }
        // Clear suggestions and selections after adding
        suggestedSubtasks = []
        checkedSubtasks = []
    }
    
    private func addTask() {
        // Ensure the date is not in the past
        let date = max(dueDate, Date())
        
        let task = Task(
            title: title,
            description: description,
            dueDate: date,
            isCompleted: false,
            priority: selectedPriority
        )
        
        taskManager.addTask(task)
        dismiss()
    }
}

private struct TitleInputSection: View {
    @Binding var title: String
    let voiceInputManager: VoiceInputManager
    let isAnimating: Bool
    let inputBackground: Color
    var body: some View {
        TaskInputCard(title: "Task Title", systemImage: "pencil.circle.fill") {
            HStack {
                TextField("What do you need to do?", text: $title)
                    .font(.title3)
                    .padding(.horizontal)
                    .frame(height: 50)
                    .background(inputBackground)
                    .cornerRadius(12)
                    .foregroundColor(.primary)
                Button(action: {
                    voiceInputManager.transcribeSpeechToText { transcribedText in
                        if !transcribedText.isEmpty {
                            DispatchQueue.main.async { title = transcribedText }
                        }
                    }
                }) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(voiceInputManager.isRecording ? .red : .orange)
                        .padding(10)
                        .background(voiceInputManager.isRecording ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .clipShape(Circle())
                        .scaleEffect(voiceInputManager.isRecording ? 1.2 : 1)
                        .animation(.easeInOut(duration: 0.6), value: voiceInputManager.isRecording)
                }
                .disabled(voiceInputManager.isRecording)
                .accessibilityLabel("Record task title")
            }
        }
        .offset(x: isAnimating ? 0 : -300)
    }
}

private struct DescriptionInputSection: View {
    @Binding var description: String
    let voiceInputManager: VoiceInputManager
    let isAnimating: Bool
    let inputBackground: Color
    var body: some View {
        TaskInputCard(title: "Description", systemImage: "text.alignleft") {
            VStack(spacing: 8) {
                TextEditor(text: $description)
                    .frame(height: 100)
                    .padding(.horizontal)
                    .background(inputBackground)
                    .cornerRadius(12)
                    .foregroundColor(.primary)
                HStack {
                    Spacer()
                    Button(action: {
                        voiceInputManager.transcribeSpeechToText { transcribedText in
                            if !transcribedText.isEmpty {
                                DispatchQueue.main.async { description = transcribedText }
                            }
                        }
                    }) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(voiceInputManager.isRecording ? .red : .orange)
                            .padding(10)
                            .background(voiceInputManager.isRecording ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                            .clipShape(Circle())
                            .scaleEffect(voiceInputManager.isRecording ? 1.2 : 1)
                            .animation(.easeInOut(duration: 0.6), value: voiceInputManager.isRecording)
                    }
                    .disabled(voiceInputManager.isRecording)
                    .padding(.trailing)
                    .accessibilityLabel("Record description")
                }
            }
        }
        .offset(x: isAnimating ? 0 : 300)
    }
}

private struct BreakDownButtonSection: View {
    let isBreakingDown: Bool
    let isTitleEmpty: Bool
    let isDescriptionEmpty: Bool
    let gradientColors: [Color]
    let isAnimating: Bool
    let breakDownAction: () -> Void
    var body: some View {
        Button(action: { breakDownAction() }) {
            HStack {
                if isBreakingDown {
                    ProgressView().tint(.white)
                }
                Text("Break down with AI")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
            .shadow(radius: 6)
        }
        .disabled((isTitleEmpty && isDescriptionEmpty) || isBreakingDown)
        .padding(.horizontal)
        .offset(y: isAnimating ? 0 : 300)
    }
}

private struct SubtasksSection: View {
    let suggestedSubtasks: [String]
    @Binding var checkedSubtasks: Set<Int>
    let subtaskError: String?
    let gradientColors: [Color]
    let isAnimating: Bool
    let addCheckedSubtasks: () -> Void
    var body: some View {
        Group {
            if let error = subtaskError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .offset(y: isAnimating ? 0 : 300)
            }
            if !suggestedSubtasks.isEmpty {
                TaskInputCard(title: "Suggested Subtasks", systemImage: "list.bullet.rectangle") {
                    VStack {
                        ForEach(suggestedSubtasks.indices, id: \.self) { index in
                            HStack {
                                Button(action: {
                                    if checkedSubtasks.contains(index) {
                                        checkedSubtasks.remove(index)
                                    } else {
                                        checkedSubtasks.insert(index)
                                    }
                                }) {
                                    Image(systemName: checkedSubtasks.contains(index) ? "checkmark.square.fill" : "square")
                                        .foregroundColor(checkedSubtasks.contains(index) ? .orange : .gray)
                                        .imageScale(.large)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text(suggestedSubtasks[index])
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                        Button(action: { addCheckedSubtasks() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Subtasks as Tasks")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(radius: 6)
                        }
                        .disabled(checkedSubtasks.isEmpty)
                        .padding(.top)
                    }
                    .padding(.horizontal)
                }
                .offset(y: isAnimating ? 0 : 300)
            }
        }
    }
}

private struct PrioritySelectionSection: View {
    @Binding var selectedPriority: TaskPriority
    let isAnimating: Bool
    var body: some View {
        TaskInputCard(title: "Priority", systemImage: "flag.fill") {
            HStack(spacing: 16) {
                ForEach(TaskPriority.allCases) { priority in
                    PriorityButton(priority: priority, isSelected: selectedPriority == priority) {
                        selectedPriority = priority
                    }
                }
            }
            .padding(.horizontal)
        }
        .offset(y: isAnimating ? 0 : 300)
    }
}

private struct DueDateSection: View {
    @Binding var dueDate: Date
    let isAnimating: Bool
    let inputBackground: Color
    var body: some View {
        TaskInputCard(title: "Due Date", systemImage: "calendar") {
            DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.automatic)
                .padding()
                .background(inputBackground)
                .cornerRadius(12)
                .foregroundColor(.primary)
        }
        .offset(y: isAnimating ? 0 : 300)
    }
}

private struct AddAndSyncButtonsSection: View {
    let title: String
    let gradientColors: [Color]
    let isAnimating: Bool
    let addTask: () -> Void
    let canSync: Bool
    let syncAction: () -> Void
    var body: some View {
        VStack(spacing: 8) {
            Button(action: addTask) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Task")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(radius: 8)
            }
            .disabled(title.isEmpty)
            .opacity(title.isEmpty ? 0.6 : 1.0)
            .padding(.top)
            Button(action: syncAction) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                    Text("Sync this task to Calendar")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(radius: 8)
            }
            .disabled(!canSync)
        }
    }
}

/// Editable model for suggested subtasks to allow editing and selection
struct EditableSubtask: Identifiable {
    let id = UUID()
    var text: String
    var isSelected: Bool
}

private struct BackgroundGradientView: View {
    let colors: [Color]
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// Supporting Views
struct TaskInputCard<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.orange)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal)
            
            content
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: priority.icon)
                    .imageScale(.large)
                Text(priority.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? priority.color.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? priority.color : .gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? priority.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// Add this to your Task model
enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "tortoise.fill"
        case .medium: return "hare.fill"
        case .high: return "flame.fill"
        }
    }
}
