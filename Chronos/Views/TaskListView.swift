import SwiftUI

struct TaskListView: View {
    @ObservedObject var taskManager: TaskManager
    @Binding var showingAddTask: Bool
    @Binding var showingThemeStore: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Title and Action Buttons
            HStack {
                Text("Tasks")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 20) {
                    // Theme Store Button
                    Button(action: { showingThemeStore = true }) {
                        Image(systemName: "paintpalette.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                            .frame(width: 50, height: 50)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Add Task Button
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.orange)
                            .frame(width: 50, height: 50)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .padding(.bottom, 16)
            
            // Task List
            List {
                ForEach(taskManager.tasks) { task in
                    TaskRow(task: task, taskManager: taskManager)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle())
        }
        .background(Color(.systemBackground))
    }
}

struct TaskRow: View {
    let task: Task
    @ObservedObject var taskManager: TaskManager
    @State private var showingPointsAnimation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Priority indicator
            Circle()
                .fill(task.priority.color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .gray : .primary)
                
                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                HStack {
                    Image(systemName: task.priority.icon)
                        .foregroundColor(task.priority.color)
                    Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Complete/Uncomplete button with animation
            Button(action: {
                if !task.isCompleted {
                    showingPointsAnimation = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingPointsAnimation = false
                    }
                }
                withAnimation {
                    taskManager.toggleTaskCompletion(task)
                }
            }) {
                ZStack {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.title2)
                    
                    if showingPointsAnimation {
                        Text("+\(Task.COMPLETION_POINTS)")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                            .offset(y: showingPointsAnimation ? -20 : 0)
                            .opacity(showingPointsAnimation ? 0 : 1)
                            .animation(.easeOut(duration: 1), value: showingPointsAnimation)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

enum TaskFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case today = "Today"
    case upcoming = "Upcoming"
    
    var id: String { self.rawValue }
}
