import SwiftUI

struct CalendarTaskRow: View {
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

                if !task.description.isEmpty {
                    Text(task.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundColor(task.priority.color)
            }

            Spacer()

            // Complete/Uncomplete button
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
                        .imageScale(.large)

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
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}
