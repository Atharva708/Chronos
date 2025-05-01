import SwiftUI

struct AddTodayTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var taskManager: TaskManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPriority = TaskPriority.medium
    @State private var isAnimating = false
    @State private var showEmoji = false
    
    let gradientColors = [Color.orange, Color.pink]
    let emojis = ["🚀", "⭐️", "💪", "✨", "🎯", "🌟"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated background
                LinearGradient(colors: gradientColors.map { $0.opacity(0.15) },
                             startPoint: .topLeading,
                             endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Motivational Header
                        VStack(spacing: 8) {
                            Text("Let's Crush Today's Goals!")
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                            
                            Text("What amazing thing are you planning to do?")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                        }
                        .padding(.top)
                        
                        // Title Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(.orange)
                                Text("Task Title")
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            
                            TextField("Enter your task", text: $title)
                                .font(.title3)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .offset(x: isAnimating ? 0 : -300)
                        
                        // Description Input
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.quote")
                                    .foregroundStyle(.orange)
                                Text("Description")
                                    .font(.headline)
                            }
                            .padding(.horizontal)
                            
                            TextEditor(text: $description)
                                .frame(height: 100)
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .offset(x: isAnimating ? 0 : 300)
                        
                        // Priority Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How important is this task?")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 12) {
                                ForEach(TaskPriority.allCases) { priority in
                                    Button(action: {
                                        withAnimation(.spring) {
                                            selectedPriority = priority
                                            showEmoji = true
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                showEmoji = false
                                            }
                                        }
                                    }) {
                                        VStack(spacing: 12) {
                                            Image(systemName: priority.icon)
                                                .font(.title2)
                                                .foregroundColor(selectedPriority == priority ? priority.color : .gray)
                                            
                                            Text(priority.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedPriority == priority ? priority.color : .gray)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 90)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedPriority == priority ? priority.color.opacity(0.1) : Color.white)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedPriority == priority ? priority.color : Color.gray.opacity(0.2), lineWidth: 2)
                                        )
                                    }
                                    .scaleEffect(selectedPriority == priority ? 1.05 : 1.0)
                                    .animation(.spring(response: 0.3), value: selectedPriority)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10)
                        .offset(y: isAnimating ? 0 : 300)
                        
                        // Create Button
                        Button(action: addTaskWithAnimation) {
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                Text("Create Amazing Task")
                                    .fontWeight(.semibold)
                                Image(systemName: "sparkles")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(colors: title.isEmpty ? [.gray] : gradientColors,
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                            .padding(.horizontal)
                        }
                        .disabled(title.isEmpty)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                    }
                    .padding()
                }
                
                // Floating emojis
                if showEmoji {
                    ForEach(0..<6) { index in
                        Text(emojis[index])
                            .font(.system(size: 40))
                            .offset(y: showEmoji ? -100 : 0)
                            .opacity(showEmoji ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1)
                                .delay(Double(index) * 0.1),
                                value: showEmoji
                            )
                    }
                }
            }
            .navigationTitle("New Task")
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
    
    private func addTaskWithAnimation() {
        showEmoji = true
        
        let task = Task(
            title: title,
            description: description,
            dueDate: Date(),
            isCompleted: false,
            priority: selectedPriority
        )
        
        withAnimation {
            taskManager.addTask(task)
        }
        
        // Dismiss with a slight delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
} 
