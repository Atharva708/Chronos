import Foundation
import SwiftUI
import Speech
import AVFoundation
import FoundationModels // Added for Foundation Model integration

/// Privacy Usage Description comments for Info.plist:
/// NSMicrophoneUsageDescription = "This app requires access to the microphone to enable speech-to-text input."
/// NSSpeechRecognitionUsageDescription = "This app uses speech recognition to convert your voice into text."

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    private let initialTitle: String?
    private let initialDescription: String?
    @Environment(\.colorScheme) private var colorScheme
    
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
    @State private var isSyncingToCalendar = false
    @State private var calendarSyncErrorMessage: String? = nil
    
    // State to show brief toast/notification for voice-added tasks
    @State private var showVoiceAddConfirmation = false
    
    let gradientColors: [Color] = [Color.accentColor, Color.orange]
    private var backgroundGradientColors: [Color] { [Color(.systemBackground), Color(.secondarySystemBackground)] }
    private var inputBackground: Color { Color(.secondarySystemBackground) }
    
    private var isTitleEmpty: Bool { title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var isDescriptionEmpty: Bool { description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    init(taskManager: TaskManager, initialTitle: String? = nil, initialDescription: String? = nil) {
        self.taskManager = taskManager
        self._title = State(initialValue: initialTitle ?? "")
        self._description = State(initialValue: initialDescription ?? "")
        self.initialTitle = initialTitle
        self.initialDescription = initialDescription
    }
    
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
                        
                        // Voice Add Task
                        Button(action: {
                            voiceInputManager.startVoiceInput { result in
                                switch result {
                                case .success(let processedTask):
                                    let trimmed = processedTask.title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    DispatchQueue.main.async {
                                        if title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                                            // Use first line as title; rest as description
                                            let parts = trimmed.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
                                            title = String(parts.first ?? "")
                                            if parts.count > 1 {
                                                let rest = String(parts[1])
                                                description = description.isEmpty ? rest : description + "\n" + rest
                                            }
                                        } else {
                                            // Append to description if title already set
                                            description = description.isEmpty ? trimmed : description + "\n" + trimmed
                                        }
                                        // If we have a title now, create the task immediately
                                        if !title.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
                                            addTask()
                                            showVoiceAddConfirmation = true
                                        }
                                    }
                                case .failure(let error):
                                    print("Voice input failed: \(error)")
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: voiceInputManager.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                Text(voiceInputManager.isRecording ? "Stop & Create" : "Add Task by Voice")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(radius: 6)
                        }
                        .accessibilityLabel("Add task by voice")
                        .padding(.horizontal)
                        .opacity(1.0)
                        
                        // Add + Sync buttons
                        AddAndSyncButtonsSection(title: title, gradientColors: gradientColors, isAnimating: isAnimating, isSyncing: isSyncingToCalendar, addTask: addTask, canSync: !taskManager.tasks.isEmpty, syncAction: {
                            guard !isSyncingToCalendar else { return }
                            guard let lastTask = taskManager.tasks.last else { return }
                            isSyncingToCalendar = true
                            CalendarSyncManager.shared.addTaskToCalendar(task: lastTask) { success, error in
                                DispatchQueue.main.async {
                                    isSyncingToCalendar = false
                                    if success {
                                        showCalendarSyncSuccess = true
                                    } else {
                                        calendarSyncErrorMessage = error?.localizedDescription ?? "Failed to sync the task to your calendar. Please try again."
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
                Text(calendarSyncErrorMessage ?? "Failed to sync the task to your calendar. Please try again.")
            }
            .alert("Task Created", isPresented: $showVoiceAddConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your task was created from voice input.")
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
                    .foregroundStyle(.primary)
                Button(action: {
                    voiceInputManager.startVoiceInput { result in
                        switch result {
                        case .success(let processedTask):
                            if !processedTask.title.isEmpty {
                                DispatchQueue.main.async { title = processedTask.title }
                            }
                        case .failure(let error):
                            print("Voice input failed: \(error)")
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
                    .foregroundStyle(.primary)
                HStack {
                    Spacer()
                    Button(action: {
                        voiceInputManager.startVoiceInput { result in
                            switch result {
                            case .success(let processedTask):
                                if !processedTask.title.isEmpty {
                                    DispatchQueue.main.async { description = processedTask.title }
                                }
                            case .failure(let error):
                                print("Voice input failed: \(error)")
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
            .foregroundStyle(.white)
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
                                        .foregroundStyle(checkedSubtasks.contains(index) ? .orange : Color.secondary)
                                        .imageScale(.large)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text(suggestedSubtasks[index])
                                    .lineLimit(nil)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                        Button(action: { addCheckedSubtasks() }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Subtasks as Tasks")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
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
                .foregroundStyle(.primary)
        }
        .offset(y: isAnimating ? 0 : 300)
    }
}

private struct AddAndSyncButtonsSection: View {
    let title: String
    let gradientColors: [Color]
    let isAnimating: Bool
    let isSyncing: Bool
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
                .foregroundStyle(.white)
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
                    if isSyncing { ProgressView().tint(.white) }
                    Image(systemName: "calendar.badge.plus")
                    Text(isSyncing ? "Syncing…" : "Sync this task to Calendar")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(radius: 8)
            }
            .disabled(!canSync || isSyncing)
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
    @Environment(\.colorScheme) private var colorScheme
    
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
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 8, x: 0, y: 4)
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
            .background(isSelected ? priority.color.opacity(0.25) : Color(.tertiarySystemFill))
            .foregroundStyle(isSelected ? priority.color : Color.secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? priority.color : Color(.separator), lineWidth: 1)
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

