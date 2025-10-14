import SwiftUI

struct CalendarView: View {
    @ObservedObject var taskManager: TaskManager
    @State private var selectedDate = Date()
    @State private var showingAddTask = false
    
    private let calendar = Calendar.current
    
    var tasksForSelectedDate: [Task] {
        taskManager.tasks.filter { task in
            calendar.isDate(task.dueDate, inSameDayAs: selectedDate)
        }
    }
    
    var datesWithTasks: Set<Date> {
        Set(taskManager.tasks.map { calendar.startOfDay(for: $0.dueDate) })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Calendar")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading,10)
            // Calendar
            CustomDatePicker(
                selection: $selectedDate,
                datesWithTasks: datesWithTasks
            )
            .padding()
            .background(Color(.secondarySystemBackground))
            .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
            
            // Tasks for selected date
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    
                    // Enhanced Add Task Button
                    Button(action: { showingAddTask = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Task")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)
                
                if tasksForSelectedDate.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No tasks scheduled")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(tasksForSelectedDate) { task in
                                CalendarTaskRow(task: task, taskManager: taskManager)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Calendar")
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(taskManager: taskManager)
        }
    }
}

// Custom Date Picker
struct CustomDatePicker: View {
    @Binding var selection: Date
    let datesWithTasks: Set<Date>
    
    var body: some View {
        DatePicker(
            "Select Date",
            selection: $selection,
            displayedComponents: [.date]
        )
        .labelsHidden()
        .datePickerStyle(.graphical)
        .tint(.orange)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .foregroundStyle(.primary)
        // TODO: Add task markers with precise positioning if needed
    }
    
//    private func positionForDate(_ date: Date, in geometry: GeometryProxy) -> CGPoint {
//        // This is a placeholder implementation
//        // You'll need to calculate the actual position based on the date
//        CGPoint(x: 0, y: 0)
//    }
} 
