import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background decoration
                LinearGradient(gradient: Gradient(colors: [Color(.systemTeal).opacity(0.7), Color(.white), Color(.orange).opacity(0.3)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: [Color.orange.opacity(0.5), .clear]), center: .center, startRadius: 10, endRadius: 300))
                    .blur(radius: 30)
                    .offset(x: -120, y: -220)
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), .clear]), center: .center, startRadius: 10, endRadius: 220))
                    .blur(radius: 40)
                    .offset(x: 140, y: 150)
                RoundedRectangle(cornerRadius: 60)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.orange.opacity(0.13), Color.white.opacity(0.09)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 350, height: 520)
                    .blur(radius: 12)
                
                VStack(spacing: 36) {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .orange.opacity(0.10), radius: 24, y: 8)
                        VStack(spacing: 28) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color.orange.opacity(0.25), Color.white.opacity(0.13)], startPoint: .top, endPoint: .bottom))
                                    .frame(width: 90, height: 90)
                                    .shadow(color: .orange.opacity(0.05), radius: 16, y: 6)
                                Image(systemName: "checkmark.seal.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 54, height: 54)
                                    .foregroundStyle(.orange, .white)
                                    .shadow(color: .orange.opacity(0.13), radius: 10, y: 4)
                            }
                            Text("Welcome to TaskPro!")
                                .font(.system(size: 30, weight: .heavy, design: .rounded))
                                .foregroundStyle(.orange)
                                .multilineTextAlignment(.center)
                            Text("Effortless productivity.\nAdd and break down tasks with voice, AI, and style.\nEarn trophies, unlock themes, and sync with your calendar.")
                                .font(.title3)
                                .foregroundColor(.primary.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    Image(systemName: "mic.fill").foregroundColor(.blue)
                                    Text("Voice input for speed").font(.subheadline)
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "wand.and.stars").foregroundColor(.orange)
                                    Text("AI-powered subtasks").font(.subheadline)
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar.badge.plus").foregroundColor(.orange)
                                    Text("Calendar sync").font(.subheadline)
                                }
                                HStack(spacing: 12) {
                                    Image(systemName: "paintpalette.fill").foregroundColor(.teal)
                                    Text("Minimalist themes").font(.subheadline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            Button(action: {
                                hasSeenOnboarding = true
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    Text("Let's Get Started")
                                        .font(.headline.bold())
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Capsule().fill(LinearGradient(colors: [.orange, .yellow.opacity(0.7)], startPoint: .leading, endPoint: .trailing)))
                                .foregroundColor(.white)
                                .shadow(color: .orange.opacity(0.14), radius: 10, y: 3)
                            }
                            .padding(.top, 8)
                        }
                        .padding(32)
                    }
                    .frame(width: 340, height: 520)
                    Spacer(minLength: 32)
                }
            }
            .navigationTitle("")
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
