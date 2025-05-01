import SwiftUI

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var taskManager = TaskManager()
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingThemeStore = false
    @State private var showingAddTask = false
    @State private var swipeCount = 0
    @State private var tapCount = 0
    @State private var lastTapTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with theme color
                themeManager.currentTheme.background
                    .ignoresSafeArea()
                
                // Easter egg effect
                EasterEggEffect(theme: themeManager.currentTheme, isActive: $themeManager.isEasterEggActive)
                    .ignoresSafeArea()
                
                TabView {
                    TaskListView(taskManager: taskManager, showingAddTask: $showingAddTask, showingThemeStore: $showingThemeStore)
                        .tabItem {
                            Label("Tasks", systemImage: "checklist")
                        }
                    
                    CalendarView(taskManager: taskManager)
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                    
                    ProfileView(taskManager: taskManager)
                        .tabItem {
                            Label("Profile", systemImage: "person.circle")
                        }
                }
                .accentColor(.orange)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingThemeStore) {
            ThemeStoreView()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTodayTaskView(taskManager: taskManager)
        }
        .onAppear {
            // Check notification settings when app appears
            notificationManager.checkNotificationSettings()
        }
        .onTapGesture(count: 2) {
            if themeManager.currentTheme.name == "Forest" {
                themeManager.triggerEasterEgg()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { _ in
                    if themeManager.currentTheme.name == "Ocean" {
                        swipeCount += 1
                        if swipeCount >= 3 {
                            themeManager.triggerEasterEgg()
                            swipeCount = 0
                        }
                    }
                }
        )
        .onShake {
            if themeManager.currentTheme.name == "Sunset" {
                themeManager.triggerEasterEgg()
            }
        }
        .onTapGesture {
            if themeManager.currentTheme.name == "Midnight" {
                let now = Date()
                if now.timeIntervalSince(lastTapTime) < 1.0 {
                    tapCount += 1
                    if tapCount >= 3 {
                        themeManager.triggerEasterEgg()
                        tapCount = 0
                    }
                } else {
                    tapCount = 1
                }
                lastTapTime = now
            }
        }
    }
}

// MARK: - Shake Gesture Support
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

#Preview {
    ContentView()
}
