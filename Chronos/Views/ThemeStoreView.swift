import SwiftUI

struct ThemeStoreView: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var trophyManager = TrophyManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingUnlockAlert = false
    @State private var selectedTheme: AppTheme?
    @State private var isAnimating = false
    @State private var selectedCategory = 0
    
    let categories = ["All", "Unlocked", "Locked"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.orange.opacity(0.1), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 16) {
                            // Trophy Count
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                Text("\(trophyManager.trophies)")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(
                                Capsule()
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 5)
                            )
                            
                            // Current Theme Card
                            VStack(spacing: 12) {
                                Text("Current Theme")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                
                                ThemePreviewCard(
                                    theme: themeManager.currentTheme,
                                    isSelected: true,
                                    isUnlocked: true,
                                    action: {}
                                )
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.05), radius: 10)
                        }
                        .padding(.horizontal)
                        
                        // Category Picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0..<categories.count, id: \.self) { index in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = index
                                        }
                                    }) {
                                        Text(categories[index])
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(selectedCategory == index ? .orange : Color.white)
                                            )
                                            .foregroundColor(selectedCategory == index ? .white : .orange)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Themes Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach([AppTheme.ocean, AppTheme.forest, AppTheme.sunset, AppTheme.midnight, AppTheme.aurora, AppTheme.mountain, AppTheme.desert]) { theme in
                                let isUnlocked = themeManager.unlockedThemes.contains(theme.id)
                                
                                if selectedCategory == 0 || 
                                   (selectedCategory == 1 && isUnlocked) || 
                                   (selectedCategory == 2 && !isUnlocked) {
                                    ThemePreviewCard(
                                        theme: theme,
                                        isSelected: theme.id == themeManager.currentTheme.id,
                                        isUnlocked: isUnlocked,
                                        action: {
                                            if isUnlocked {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    themeManager.applyTheme(theme)
                                                    NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
                                                }
                                            } else {
                                                selectedTheme = theme
                                                showingUnlockAlert = true
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Theme Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
            .alert("Unlock Theme", isPresented: $showingUnlockAlert) {
                if let theme = selectedTheme {
                    Button("Cancel", role: .cancel) { }
                    Button("Unlock") {
                        if themeManager.unlockTheme(theme, trophies: trophyManager.trophies) {
                            withAnimation {
                                trophyManager.deductTrophies(theme.trophyCost)
                                themeManager.applyTheme(theme)
                                NotificationCenter.default.post(name: NSNotification.Name("ThemeChanged"), object: nil)
                            }
                        }
                    }
                    .foregroundColor(.orange)
                }
            } message: {
                if let theme = selectedTheme {
                    VStack(spacing: 8) {
                        Text("Unlock the \(theme.name) theme?")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("This will cost \(theme.trophyCost) trophies")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
            }
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let isUnlocked: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 12) {
                // Theme Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.background)
                        .frame(height: 120)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? .orange : Color.clear, lineWidth: 2)
                        )
                    
                    VStack(spacing: 8) {
                        Image(systemName: theme.icon)
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        
                        Text(theme.name)
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                }
                
                // Status Bar
                HStack {
                    if !isUnlocked {
                        HStack(spacing: 4) {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                            Text("\(theme.trophyCost)")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.orange)
                        }
                    } else if isSelected {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Selected")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                )
            }
            .padding(8)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.98 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ThemeStoreView()
} 