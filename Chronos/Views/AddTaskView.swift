import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var selectedPriority = TaskPriority.medium
    @State private var isAnimating = false
    
    let gradientColors = [Color.orange, Color.pink]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(colors: gradientColors.map { $0.opacity(0.1) },
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title Card
                        TaskInputCard(title: "Task Title", systemImage: "pencil.circle.fill") {
                            TextField("What do you need to do?", text: $title)
                                .font(.title3)
                                .padding(.horizontal)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .offset(x: isAnimating ? 0 : -300)
                        
                        // Description Card
                        TaskInputCard(title: "Description", systemImage: "text.alignleft") {
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding(.horizontal)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .offset(x: isAnimating ? 0 : 300)
                        
                        // Priority Selection
                        TaskInputCard(title: "Priority", systemImage: "flag.fill") {
                            HStack(spacing: 16) {
                                ForEach(TaskPriority.allCases) { priority in
                                    PriorityButton(priority: priority,
                                                 isSelected: selectedPriority == priority,
                                                 action: { selectedPriority = priority })
                                }
                            }
                            .padding(.horizontal)
                        }
                        .offset(y: isAnimating ? 0 : 300)
                        
                        // Due Date Card
                        TaskInputCard(title: "Due Date", systemImage: "calendar") {
                            DatePicker("Select Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .offset(y: isAnimating ? 0 : 300)
                        
                        // Add Button
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
                                LinearGradient(colors: gradientColors,
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .shadow(radius: 8)
                        }
                        .disabled(title.isEmpty)
                        .opacity(title.isEmpty ? 0.6 : 1.0)
                        .padding(.top)
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
        }
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
            }
            .padding(.horizontal)
            
            content
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
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