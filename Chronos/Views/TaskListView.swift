import SwiftUI

struct TaskListView: View {
    @StateObject private var taskManager = TaskManager()
    @State private var showingAddTask = false
    
    var todaysTasks: [Task] {
        taskManager.tasks.filter { task in
            Calendar.current.isDateInToday(task.dueDate)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
               
                VStack(spacing: 8) {
                    Text("Today's Progress")
                        .font(.headline)
                    ProgressBar(completed: Double(completedTodayCount),
                              total: Double(todaysTasks.count))
                        .frame(height: 8)
                        .padding(.horizontal)
                    
                    Text("\(completedTodayCount)/\(todaysTasks.count) tasks completed")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 5)
                .padding()
                
                List {
                    ForEach(todaysTasks) { task in
                        TaskRow(task: task, taskManager: taskManager)
                    }
                    .onDelete(perform: deleteTask)
                }
            }
            .navigationTitle("Today's Tasks")
            .toolbar {
                Button(action: { showingAddTask = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.orange)
                        .frame(width: 50, height: 50)
                }
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTodayTaskView(taskManager: taskManager)
        }
    }
    
    private var completedTodayCount: Int {
        todaysTasks.filter { $0.isCompleted }.count
    }
    
    private func deleteTask(at offsets: IndexSet) {
        offsets.forEach { index in
            taskManager.deleteTask(todaysTasks[index])
        }
    }
}

struct TaskRow: View {
    let task: Task
    @ObservedObject var taskManager: TaskManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title)
                    .font(.headline)
                Text(task.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            if !task.isCompleted {
                Button(action: { taskManager.completeTask(task) }) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.orange)
                        .imageScale(.large)
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .imageScale(.large)
            }
        }
        .padding(.vertical, 8)
    }
} 
